//
//  LibManager.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LibManager.h"
#import "LibraryFolder.h"
#import "ID3Reader.h"
#import "Tree.h"
#import "Tags.h"

#import <algorithm>
#import <vector>

using namespace std;

@interface LibManager ()
@property (atomic, assign) BOOL nowSearching;
@property (atomic, strong) NSString *pendingSearchQuery;
@end

@implementation LibManager

struct LibManagerImpl {
  vector<NSString *> queryWords;
  vector<bool> queryHits;
  int nHit;
  
  vector<int> needsRescan;
  vector<NSString *> lines;
};

+ (LibManager *)sharedManager {
  static LibManager *o = nil;
  if (o == nil) o = [LibManager new];
  return o;
}

- (id)init {
  if (self = [super init]) {
    impl = new LibManagerImpl;
    previousSearchQuery = @"";
    [self loadLibrary];
  }
  return self;
}

- (void)loadLibrary {
  @autoreleasepool {
    [[Tree sharedTree] clearTree];
    
    const char *fileName = [[self libPath] cStringUsingEncoding:NSUTF8StringEncoding];
    FILE *f = fopen(fileName, "r");
    
    vector<int> treePath;
    treePath.push_back(0);
    
    static const int kLineBuffSize = 1<<16;
    static char lineBuff[kLineBuffSize];
    while(fgets(lineBuff, kLineBuffSize, f) != NULL) {
      if (lineBuff[0] == 0) break;
      
      char first = lineBuff[0];
      
      if (first == '+') {
        NSString *folderName = [self stringFromBuff:lineBuff+2];
        int node = [[Tree sharedTree] addChild:folderName parent:treePath.back() song:-1];
        treePath.push_back(node);
      } else if (first == '-') {
        treePath.pop_back();
      } else if (first == '{') {
        int song = [[Tree sharedTree] newSong];
        LibrarySong *songData = [[Tree sharedTree] songDataForP:song];
        
        fgets(lineBuff, kLineBuffSize, f);
        sscanf(lineBuff, "%d", &songData->inode);

        fgets(lineBuff, kLineBuffSize, f);
        sscanf(lineBuff, "%d", &songData->lastModified);
        
        fgets(lineBuff, kLineBuffSize, f);
        NSString *fileName = [self stringFromBuff:lineBuff];

        fgets(lineBuff, kLineBuffSize, f);
        sscanf(lineBuff, "%d", &songData->lengthInSeconds);
        
        for (int i = 0; i < [Tags numberOfTags]; ++i) {
          fgets(lineBuff, kLineBuffSize, f);
          NSString *val = [self stringFromBuff:lineBuff];
          if ([val isEqualToString:@"/"]) val = @"";
          [songData->tags setTag:val forIndex:i];
        }
        
        [[Tree sharedTree] addChild:fileName parent:treePath.back() song:song];
        [[Tree sharedTree] addToSongByInodeMap:song inode:songData->inode];
          
        fgets(lineBuff, kLineBuffSize, f); // skip '}'
      } else {
        if (treePath.size() > 1) {
          treePath.pop_back();
        }
        
        NSString *folderName = [self stringFromBuff:lineBuff];
        fgets(lineBuff, kLineBuffSize, f);
        NSString *displayName = [self stringFromBuff:lineBuff];
        
        int node = [[Tree sharedTree] addChild:displayName parent:0 song:-1];
        [[Tree sharedTree] setLibraryPath:folderName forNode:node];
        treePath.push_back(node);
      }
    }
  }
}

- (NSString *)stringFromBuff:(char *)buff {
  buff[strlen(buff)-1] = 0; // remove newline
  return [NSString stringWithCString:buff encoding:NSUTF8StringEncoding];
}

- (void)rescanLibraryWithProgressBlock:(void (^)(int))progressBlock {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    @autoreleasepool {
      vector<NSString *> libraryDisplayNames;
      vector<NSString *> libraryPaths;
      for (LibraryFolder *lf in [LibraryFolder libraryFolders]) {
        libraryDisplayNames.push_back(lf.treeDisplayName);
        libraryPaths.push_back(lf.folderPath);
      }
      
      int numberOfSongs = 0;
      
      NSLog(@"walking folders..");
      NSDate *timestamp = [NSDate date];
      for (int i = 0; i < libraryPaths.size(); ++i) {
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:libraryPaths[i]];

        impl->needsRescan.push_back(-1); // marks begining of a new baseURL section
        impl->lines.push_back(libraryPaths[i]);
        impl->lines.push_back(libraryDisplayNames[i]);
        
        int lastLevel = 0;
        BOOL wasLastElementFolder = NO;
        for (NSString *file; file = [enumerator nextObject];) {
          int currentLevel = (int)enumerator.level;
          NSDictionary *stat = [enumerator fileAttributes];
          BOOL isFolder = ([stat objectForKey:NSFileType] == NSFileTypeDirectory);

          if (currentLevel <= lastLevel) { // leaving folder
            int cnt = (lastLevel-currentLevel) + (wasLastElementFolder == YES);
            for (int i = 0; i < cnt; ++i) [self exitFolderButClearIfEmpty];
          }
          
          if (isFolder) { // entering directory
            impl->lines.push_back([NSString stringWithFormat:@"+ %@", [file lastPathComponent]]);
          } else if ([[[file pathExtension] lowercaseString] isEqualToString:@"mp3"]) {
            ++numberOfSongs;
            
            int inode = [[stat objectForKey:NSFileSystemFileNumber] intValue];
            int lastModified = (int) [((NSDate *)[stat objectForKey:NSFileModificationDate]) timeIntervalSince1970];
            int song = [[Tree sharedTree] songByInode:inode];
            LibrarySong *songData = (song == -1)? NULL: [[Tree sharedTree] songDataForP:song];
            
            impl->lines.push_back(@"{");
            impl->lines.push_back([NSString stringWithFormat:@"%d", inode]);
            impl->lines.push_back([NSString stringWithFormat:@"%d", lastModified]);
            
            if (song == -1 || songData->lastModified != lastModified) {
              impl->lines.push_back(file);
              impl->needsRescan.push_back((int) (impl->lines.size()-1));
              for (int i = 0; i <= [Tags numberOfTags]; ++i) impl->lines.push_back(@"");
            } else {
              impl->lines.push_back(file.lastPathComponent);
              impl->lines.push_back([NSString stringWithFormat:@"%d", songData->lengthInSeconds]);
              for (int i = 0; i < [Tags numberOfTags]; ++i) {
                NSString *val = [songData->tags tagForIndex:i];
                if (val == nil || val.length == 0) val = @"/";
                impl->lines.push_back(val);
              }
            }
            
            impl->lines.push_back(@"}");
          }
          
          lastLevel = currentLevel;
          wasLastElementFolder = isFolder;
        }
        
        for (int i = 1; i < lastLevel; ++i) [self exitFolderButClearIfEmpty];
      }
      NSLog(@"done walking, time: %lfs, songs found: %d", -[timestamp timeIntervalSinceNow], numberOfSongs);
      
      int filesToRescan = (int) (impl->needsRescan.size() - libraryPaths.size());
      NSLog(@"rescaning %d files..", filesToRescan);
      
      progressBlock(numberOfSongs);
      progressBlock(filesToRescan);
      
      timestamp = [NSDate date];
      NSString *baseURL;
      int n = (int) impl->needsRescan.size();
      int j = -1;
      int lastSentPercentage = -1;
      for (int i = 0; i < n; ++i) {
        int percentage = (double)(i+1) / n * 100.;
        if (percentage != lastSentPercentage) {
          progressBlock(percentage);
          lastSentPercentage = percentage;
        }
        int x = impl->needsRescan[i];
        if (x == -1) {
          baseURL = libraryPaths[++j];
        } else {
          NSString *file = impl->lines[x];
          impl->lines[x++] = file.lastPathComponent;
          ID3Reader *id3 = [[ID3Reader alloc] initWithFile:[baseURL stringByAppendingPathComponent:file]];
          if (id3 == nil) {
            NSLog(@"id3 read failed for: %@", [baseURL stringByAppendingPathComponent:file]);
            impl->lines[x++] = @"0"; // length
            for (int q = 0; q < [Tags numberOfTags]; ++q) impl->lines[x++] = @"/";
          } else {
            impl->lines[x++] = [NSString stringWithFormat:@"%d", [id3 lengthInSeconds]];
            for (int q = 0; q < [Tags numberOfTags]; ++q) {
              NSString *val = [id3 tag:[Tags tagNameForIndex:q]];
              if (val == nil || val.length == 0) val = @"/";
              impl->lines[x++] = val;
            }
          }
        }
      }
      NSLog(@"done rescaning, time: %lfs", -[timestamp timeIntervalSinceNow]);

      int length = 0;
      for (auto it = impl->lines.begin(); it != impl->lines.end(); ++it) length += (*it).length + 1;
      NSMutableString *libStr = [NSMutableString stringWithCapacity:length];
      for (auto it = impl->lines.begin(); it != impl->lines.end(); ++it) {
        [libStr appendString:*it];
        [libStr appendString:@"\n"];
      }
      [libStr writeToFile:[self libPath] atomically:YES encoding:NSUTF8StringEncoding error:nil];

//      [self loadLibrary];
      dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kLibManagerRescanedLibraryNotification object:nil];
      });
      
      impl->needsRescan.clear();
      impl->lines.clear();
    }
  });
}

- (void)exitFolderButClearIfEmpty {
  NSString *lastPushed = impl->lines.back();
  if ([lastPushed hasPrefix:@"+ "]) impl->lines.pop_back();
  else impl->lines.push_back(@"-");
}

#pragma mark - search

- (void)performSearch:(NSString *)query {
//  if (self.nowSearching) {
//    self.pendingSearchQuery = query;
////    NSLog(@"now searching, setting pending query to %@", query);
//    return;
//  }
//  
//  self.nowSearching = YES;
//  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//    NSString *currentQuery = [[NSString alloc] initWithString:query];
//    
//    for (;;) {
////      NSDate *stamp = [NSDate date];
//      impl->queryWords.clear();
//      for (NSString *q in [currentQuery componentsSeparatedByString:@" "]) {
//        NSString *s = [q stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//        if (s.length > 0) impl->queryWords.push_back(s);
//      }
//      
//      impl->queryHits.resize(impl->queryWords.size(), false);
//      appendedCharactersToQuery = [currentQuery hasPrefix:previousSearchQuery];
//      poppedCharactersFromQuery = [previousSearchQuery hasPrefix:currentQuery];
//      [self traverse:root];
////      NSLog(@"search time %lfms", -[stamp timeIntervalSinceNow]*1000.0);
//      
//      previousSearchQuery = [[NSString alloc] initWithString:currentQuery];
//      if (self.pendingSearchQuery) {
//        currentQuery = [[NSString alloc] initWithString:self.pendingSearchQuery];
//        self.pendingSearchQuery = nil;
//      } else break;
//    }
//    
//    self.nowSearching = NO;
//    dispatch_sync(dispatch_get_main_queue(), ^{
//      [[NSNotificationCenter defaultCenter] postNotificationName:kLibManagerFinishedSearchNotification object:nil];
//    });
//  });
//}
//
//- (int)traverse:(TreeNode *)node {
//  if (poppedCharactersFromQuery && (node.searchState == 2 || node.searchState == 3)) return 2;
//  if (appendedCharactersToQuery && node.searchState == 0) return 0;
//  
//  vector<int> modified;
//
//  for (int i = 0; i < impl->queryWords.size(); ++i) {
//    if (impl->queryHits[i]) continue;
//    if ([node.name rangeOfString:impl->queryWords[i] options:NSCaseInsensitiveSearch].location == NSNotFound) {
//      BOOL foundInTag = NO;
//      
//      if ([node isKindOfClass:[TreeLeaf class]]) {
//        NSDictionary *d = ((TreeLeaf *)node).song.tagsDictionary;
//        for (id key in d) {
//          NSString *val = d[key];
//          if ([val rangeOfString:impl->queryWords[i] options:NSCaseInsensitiveSearch].location != NSNotFound) {
//            foundInTag = YES;
//            break;
//          }
//        }
//      }
//        
//      if (!foundInTag) continue;
//    }
//    
//    impl->queryHits[i] = true;
//    ++impl->nHit;
//    modified.push_back(i);
//  }
//  
//  BOOL was2 = (node.searchState == 2);
//  node.searchState = 0;
//  
//  if (impl->nHit == impl->queryWords.size()) {
//    node.searchState = 2;
//  } else {
//    for (int i = 0; i < node.childrenVectorCount; ++i) {
//      TreeNode *child = [node childrenVectorAtIndex:i];
//      if (was2) child.searchState = -1; // this will soon be overwritten by 0, it's just for avoiding appendedcharacters if to falsely fire
//      if ([self traverse:child]) node.searchState = 1;
//    }
//  }
//  
//  for (int i = 0; i < modified.size(); ++i) {
//    --impl->nHit;
//    impl->queryHits[modified[i]] = false;
//  }
//  
//  return node.searchState;
}

#pragma mark - util

- (NSString *)libPath {
  return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"martin.lib"];
}

@end
