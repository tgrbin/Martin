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
  
  NSString *libPath = [[NSBundle mainBundle] pathForResource:@"martin" ofType:@"lib"];
  NSString *file = [[NSString alloc] initWithContentsOfFile:libPath encoding:NSUTF8StringEncoding error:nil];
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
      song.lengthInSeconds = [[enumerator nextObject] intValue];
      
      NSString *fileName = [enumerator nextObject];
      song.filename = [[path componentsJoinedByString:@"/"] stringByAppendingPathComponent:fileName];
      
      NSMutableDictionary *tags = [NSMutableDictionary new];
      for (NSString *tag in [LibraryTags tags]) [tags setObject:[enumerator nextObject] forKey:tag];
      song.tagsDictionary = tags;
      
      TreeLeaf *leaf = [[TreeLeaf alloc] initWithName:[fileName stringByDeletingPathExtension]];
      leaf.song = song;
      [(TreeNode*)[treePath lastObject] addChild:leaf];
      
      impl->songs.push_back(song);
      
      [enumerator nextObject]; // preskoci }
    } else {
      if (treePath.count > 0) {
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

@end
