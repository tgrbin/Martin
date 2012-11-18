//
//  LibManager.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LibManager.h"
#import "TreeNode.h"
#import "TreeLeaf.h"
#import "Song.h"
#import "LibraryTags.h"
#import "LibraryFolder.h"
#import "ID3Reader.h"

#import <algorithm>
#import <vector>

using namespace std;

@implementation LibManager

struct LibManagerImpl {
  vector<Song *> songs;
  
  vector<NSString *> queryWords;
  vector<bool> queryHits;
  int nHit;
};

struct compareSongs {
  bool operator ()(Song* __strong const &a, Song* __strong const &b) {
    return a.inode < b.inode;
  }
};

+ (LibManager *)sharedManager {
  static LibManager *o = nil;
  if (o == nil) o = [LibManager new];
  return o;
}

- (id)init {
  if (self = [super init]) {
    impl = new LibManagerImpl();
    [self loadLibrary];
  }
  return self;
}

- (void)loadLibrary {
  impl->songs.clear();
  
  NSString *file = [[NSString alloc] initWithContentsOfFile:[self libPath] encoding:NSUTF8StringEncoding error:nil];
  NSArray *lines = [file componentsSeparatedByString:@"\n"];
  NSEnumerator *enumerator = [lines objectEnumerator];
  
  root = [[TreeNode alloc] initWithName:@"root"];
  root.searchState = 2;
  
  NSMutableArray *path = [NSMutableArray new];
  NSMutableArray *treePath = [[NSMutableArray alloc] initWithObjects:root, nil];
  
  for (NSString *line; line = [enumerator nextObject];) {
    if ([line length] == 0) break;
    
    char first = [line characterAtIndex:0];
    
    if (first == '+') {
      NSString *folderName = [line substringFromIndex:2];
      TreeNode *node = [[TreeNode alloc] initWithName:folderName];
      TreeNode *curr = [treePath lastObject];

      [path addObject:folderName];
      [treePath addObject:node];
      [curr addChild:node];
    } else if (first == '-') {
      [path removeLastObject];
      [treePath removeLastObject];
    } else if (first == '{') {
      Song *song = [Song new];
      song.inode = [[enumerator nextObject] intValue];
      song.lastModified = [[enumerator nextObject] intValue];
      NSString *fileName = [enumerator nextObject];
      song.filename = [[path componentsJoinedByString:@"/"] stringByAppendingPathComponent:fileName];

      song.lengthInSeconds = [[enumerator nextObject] intValue];
      
      NSMutableDictionary *tags = [NSMutableDictionary new];
      for (NSString *tag in [LibraryTags tags]) {
        NSString *val = [enumerator nextObject];
        if ([val isEqualToString:@"/"]) val = @"";
        [tags setObject:val forKey:tag];
      }
      song.tagsDictionary = tags;
      
      TreeLeaf *leaf = [[TreeLeaf alloc] initWithName:[fileName stringByDeletingPathExtension]];
      leaf.song = song;
      [(TreeNode*)[treePath lastObject] addChild:leaf];
      
      impl->songs.push_back(song);
      
      [enumerator nextObject]; // preskoci }
    } else {
      if (path.count > 0) {
        [treePath removeLastObject];
        [path removeLastObject];
      }
      
      [path addObject:line];
      
      TreeNode *node = [[TreeNode alloc] initWithName:[enumerator nextObject]];
      [root addChild:node];
      [treePath addObject:node];
    }
  }
  
  sort(impl->songs.begin(), impl->songs.end(), compareSongs());
}

- (TreeNode *)treeRoot {
  return root;
}

- (Song *)songByID:(int)ID {
  Song *ref = [Song new];
  ref.inode = ID;
  auto iterator = lower_bound(impl->songs.begin(), impl->songs.end(), ref, compareSongs());
  return (iterator == impl->songs.end())? nil: *iterator;
}

- (void)rescanLibrary {
  vector<NSString *> lines;
  vector<int> needsRescan;
  NSArray *libraryFolders = [LibraryFolder libraryFolders];
  int numberOfTags = (int) [LibraryTags tags].count;
  int numberOfSongs = 0;
  
  NSLog(@"walking directory..");
  NSDate *timestamp = [NSDate date];
  for (LibraryFolder *lf in libraryFolders) {
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:lf.folderPath];

    needsRescan.push_back(-1); // marks begining of new baseURL section
    lines.push_back(lf.folderPath);
    lines.push_back(lf.treeDisplayName);
    
    int lastLevel = 1;
    for (NSString *file; file = [enumerator nextObject];) {
      int currentLevel = (int)enumerator.level;
      NSDictionary *stat = [enumerator fileAttributes];
      
      if (currentLevel < lastLevel) { // leaving folder
        for (int i = 0; i < lastLevel-currentLevel; ++i) lines.push_back(@"-");
      }
      
      if ([stat objectForKey:NSFileType] == NSFileTypeDirectory) { // entering directory
        lines.push_back([NSString stringWithFormat:@"+ %@", [file lastPathComponent]]);
      } else if ([[[file pathExtension] lowercaseString] isEqualToString:@"mp3"]) {
        ++numberOfSongs;
        
        int inode = [[stat objectForKey:NSFileSystemFileNumber] intValue];
        int lastModified = (int) [((NSDate *)[stat objectForKey:NSFileModificationDate]) timeIntervalSince1970];
        Song *song = [self songByID:inode];
        
        lines.push_back(@"{");
        lines.push_back([NSString stringWithFormat:@"%d", inode]);
        lines.push_back([NSString stringWithFormat:@"%d", lastModified]);
        lines.push_back(file);
        
        if (song == nil || song.lastModified != lastModified) {
          needsRescan.push_back((int) (lines.size()-1));
          for (int i = 0; i <= numberOfTags; ++i) lines.push_back(@"");
        } else {
          lines.push_back([NSString stringWithFormat:@"%d", song.lengthInSeconds]);
          for (NSString *tag in [LibraryTags tags]) {
            NSString *val = [song.tagsDictionary objectForKey:tag];
            if (val == nil || val.length == 0) val = @"/";
            lines.push_back(val);
          }
        }
        
        lines.push_back(@"}");
      }
      
      lastLevel = currentLevel;
    }
  }
  NSLog(@"done walking, time: %lfms, songs found: %d", -[timestamp timeIntervalSinceNow]/1000., numberOfSongs);
  
  NSLog(@"rescaning %ld files..", needsRescan.size() - libraryFolders.count);
  timestamp = [NSDate date];
  NSString *baseURL;
  int j = -1;
  for (auto it = needsRescan.begin(); it != needsRescan.end(); ++it) {
    if (*it == -1) {
      baseURL = [[libraryFolders objectAtIndex:++j] folderPath];
    } else {
      NSString *file = lines[*it];
      ID3Reader *id3 = [[ID3Reader alloc] initWithFile:[baseURL stringByAppendingPathComponent:file]];
      lines[*it + 1] = [NSString stringWithFormat:@"%d", [id3 lengthInSeconds]];
      for (int i = 0; i < numberOfTags; ++i) {
        NSString *val = [id3 tag:[[LibraryTags tags] objectAtIndex:i]];
        if (val == nil || val.length == 0) val = @"/";
        lines[*it + 2 + i] = val;
      }
    }
  }
  NSLog(@"done rescaning, time: %lf", -[timestamp timeIntervalSinceNow]/1000.);

  int length = 0;
  for (auto it = lines.begin(); it != lines.end(); ++it) length += (*it).length + 1;
  NSMutableString *libStr = [NSMutableString stringWithCapacity:length];
  for (auto it = lines.begin(); it != lines.end(); ++it) {
    [libStr appendString:*it];
    [libStr appendString:@"\n"];
  }
  [libStr writeToFile:[self libPath] atomically:YES encoding:NSUTF8StringEncoding error:nil];

  [self loadLibrary];
  [[NSNotificationCenter defaultCenter] postNotificationName:kLibManagerRescanedLibraryNotification object:nil];
}

#pragma mark - search

- (void)performSearch:(NSString *) query {
  impl->queryWords.clear();
  
  for (NSString *q in [query componentsSeparatedByString:@" "]) {
    NSString *s = [q stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (s.length > 0) impl->queryWords.push_back(s);
  }
  
  impl->nHit = 0;
  impl->queryHits.resize(impl->queryWords.size());
  fill(impl->queryHits.begin(), impl->queryHits.end(), false);
  
  [self traverse:root];
}

- (int)traverse:(TreeNode *)node {
  vector< int > modified;

  for (int i = 0; i < impl->queryWords.size(); ++i) {
    if (impl->queryHits[i]) continue;
    if ([node.name rangeOfString:impl->queryWords[i] options:NSCaseInsensitiveSearch].location == NSNotFound) continue;
    
    impl->queryHits[i] = true;
    ++impl->nHit;
    modified.push_back(i);
  }
  
  node.searchState = 0;
  
  if (impl->nHit == impl->queryWords.size()) {
    node.searchState = 2;
  } else {
    for (TreeNode *c in node.children) {
      if ([self traverse:c]) node.searchState = 1;
    }
  }
  
  for (int i = 0; i < modified.size(); ++i) {
    --impl->nHit;
    impl->queryHits[i] = false;
  }
  
  return node.searchState;
}

#pragma mark - util

- (NSString *)libPath {
  return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"martin.lib"];
}

@end
