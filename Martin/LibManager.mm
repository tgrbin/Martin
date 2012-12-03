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

static const int kLineBuffSize = 1<<16;
static char lineBuff[kLineBuffSize];

- (void)loadLibrary {
  @autoreleasepool {
    [[Tree sharedTree] clearTree];
    
    FILE *f = fopen(toCstr([self libPath]), "r");
    if (f == NULL) return;
    
    vector<int> treePath(1, 0);
    
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
        struct LibrarySong *songData = [[Tree sharedTree] songDataForP:song];
        
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
    
    fclose(f);
  }
}

- (NSString *)stringFromBuff:(char *)buff {
  buff[strlen(buff)-1] = 0; // remove newline
  return [NSString stringWithCString:buff encoding:NSUTF8StringEncoding];
}

- (void)rescanLibraryWithProgressBlock:(void (^)(int))progressBlock {
  __block id selfRef = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [selfRef rescanLibrary:progressBlock];
    [selfRef loadLibrary];
    dispatch_sync(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kLibManagerRescanedLibraryNotification object:nil];
    });
  });
}

- (void)rescanLibrary:(void (^)(int))block {
  @autoreleasepool {
    vector<NSString *> libraryDisplayNames;
    vector<NSString *> libraryPaths;
    for (LibraryFolder *lf in [LibraryFolder libraryFolders]) {
      libraryDisplayNames.push_back(lf.treeDisplayName);
      libraryPaths.push_back(lf.folderPath);
    }
    
    FILE *f = fopen(toCstr([self rescanPath]), "w");
    int lineNumber = 0;
    
    NSLog(@"walking folders..");
    NSDate *timestamp = [NSDate date];
    int numberOfSongs = 0, lastSongPos = -1;
    vector<int> needsRescan;
    vector<int> emptyFolders;
    vector<int> foldersStack;
    for (int i = 0; i < libraryPaths.size(); ++i) {
      NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:libraryPaths[i]];
      
      fprintf(f, "%s\n", toCstr(libraryPaths[i]));
      fprintf(f, "%s\n", toCstr(libraryDisplayNames[i]));
      lineNumber += 2;
      
      int lastLevel = 0;
      BOOL wasLastElementFolder = NO;
      for (NSString *file; file = [enumerator nextObject];) {
        int currentLevel = (int)enumerator.level;
        NSDictionary *stat = [enumerator fileAttributes];
        BOOL isFolder = ([stat objectForKey:NSFileType] == NSFileTypeDirectory);
        
        if (currentLevel <= lastLevel) { // leaving folder
          int cnt = (lastLevel-currentLevel) + (wasLastElementFolder == YES);
          for (int i = 0; i < cnt; ++i) {
            fprintf(f, "-\n");
            ++lineNumber;
            if (foldersStack.back() > lastSongPos) emptyFolders.push_back(foldersStack.back());
            foldersStack.pop_back();
          }
        }
        
        if (isFolder) { // entering directory
          fprintf(f, "+ %s\n", toCstr([file lastPathComponent]));
          foldersStack.push_back(lineNumber++);
        } else if ([[[file pathExtension] lowercaseString] isEqualToString:@"mp3"]) {
          ++numberOfSongs;
          lastSongPos = lineNumber;
          
          int inode = [[stat objectForKey:NSFileSystemFileNumber] intValue];
          int lastModified = (int) [((NSDate *)[stat objectForKey:NSFileModificationDate]) timeIntervalSince1970];
          int song = [[Tree sharedTree] songByInode:inode];
          struct LibrarySong *songData = (song == -1)? NULL: [[Tree sharedTree] songDataForP:song];
          
          fprintf(f, "{\n%d\n%d\n", inode, lastModified);
          lineNumber += 3;
          
          if (song == -1 || songData->lastModified != lastModified) {
            fprintf(f, "%s\n", toCstr(file));
            needsRescan.push_back(lineNumber++);
            for (int i = 0; i <= [Tags numberOfTags]; ++i) fprintf(f, "\n");
            lineNumber += [Tags numberOfTags] + 1;
          } else {
            fprintf(f, "%s\n%d\n", toCstr([file lastPathComponent]), songData->lengthInSeconds);
            lineNumber += 2;
            for (int i = 0; i < [Tags numberOfTags]; ++i) {
              NSString *val = [songData->tags tagForIndex:i];
              if (val == nil || val.length == 0) fprintf(f, "/\n");
              else fprintf(f, "%s\n", toCstr(val));
              ++lineNumber;
            }
          }
          
          fprintf(f, "}\n");
          ++lineNumber;
        }
        
        lastLevel = currentLevel;
        wasLastElementFolder = isFolder;
      }
      
      for (int i = 1; i < lastLevel; ++i) {
        fprintf(f, "-\n");
        ++lineNumber;
        if (foldersStack.back() > lastSongPos) emptyFolders.push_back(foldersStack.back());
        foldersStack.pop_back();
      }
    }
    fclose(f);
    
    NSLog(@"done walking, time: %lfs, songs found: %d", -[timestamp timeIntervalSinceNow], numberOfSongs);
    
    NSLog(@"rescaning %d files..", (int)needsRescan.size());
    
    block(numberOfSongs);
    block((int)needsRescan.size());
    
    timestamp = [NSDate date];
    
    f = fopen(toCstr([self rescanPath]), "r");
    FILE *g = fopen(toCstr([self rescanHelperPath]), "w");
    int emptyFolderCount = 0, nextEmptyFolderIndex = 0;
    emptyFolders.push_back(-1);
    int songStart = -1;
    int lastBaseURL = -2;
    NSString *baseURL;
    int nextRescanIndex = 0;
    ID3Reader *id3 = nil;
    BOOL id3Failed = NO;
    for (int ln = 0; fgets(lineBuff, kLineBuffSize, f) != NULL; ++ln) {
      
      BOOL writeThrough = YES;
      if (lineBuff[0] == '+') {
        if (ln == emptyFolders[nextEmptyFolderIndex]) {
          ++nextEmptyFolderIndex;
          ++emptyFolderCount;
          writeThrough = NO;
        }
      } else if (lineBuff[0] == '-') {
        if (emptyFolderCount > 0) {
          --emptyFolderCount;
          writeThrough = NO;
        }
      } else if (lineBuff[0] == '{') {
        songStart = ln;
      } else if (lineBuff[0] == '}') {
        songStart = -1;
        if (id3) {
          [id3 release];
          id3 = nil;
        }
      } else if (songStart == -1) {
        if (lastBaseURL != ln-1) {
          baseURL = stringFromLineBuff();
          lastBaseURL = ln;
        }
      } else if (songStart != -1) {
        if (ln == needsRescan[nextRescanIndex]) {
          NSString *path = stringFromLineBuff();
          NSString *fullPath = [baseURL stringByAppendingPathComponent:path];
          id3 = [[ID3Reader alloc] initWithFile:fullPath];
          if (id3 == nil) {
            NSLog(@"id3 read failed for: %@", path);
            id3Failed = YES;
          } else {
            id3Failed = NO;
          }
          strcpy(lineBuff, toCstr([path lastPathComponent]));
          ++nextRescanIndex;
        } else if (id3 != nil || id3Failed) {
          int fieldPos = ln-songStart-4;
          if (fieldPos == 0) {
            sprintf(lineBuff, "%d", id3Failed? 0: id3.lengthInSeconds);
          } else {
            if (id3Failed) {
              strcpy(lineBuff, "/");
            } else {
              NSString *tagVal = [id3 tag:[Tags tagNameForIndex:fieldPos-1]];
              if (tagVal == nil || tagVal.length == 0) strcpy(lineBuff, "/");
              else strcpy(lineBuff, toCstr(tagVal));
            }
          }
        }
      }
      
      if (writeThrough) {
        fprintf(g, "%s", lineBuff);
        if (lineBuff[strlen(lineBuff)-1] != '\n') fprintf(g, "\n");
      }
      fflush(g);
    }
    
    fclose(g);
    
    [[NSFileManager defaultManager] removeItemAtPath:[self libPath] error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:[self rescanHelperPath] toPath:[self libPath] error:nil];
    
    NSLog(@"done rescaning, time: %lfs", -[timestamp timeIntervalSinceNow]);
  }
}

static NSString *stringFromLineBuff() {
  lineBuff[strlen(lineBuff)-1] = 0;
  return [NSString stringWithCString:lineBuff encoding:NSUTF8StringEncoding];
}

static const char *toCstr(NSString *s) {
  return [s cStringUsingEncoding:NSUTF8StringEncoding];
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

- (NSString *)rescanPath {
  return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"martin_rescan.lib"];
}

- (NSString *)rescanHelperPath {
  return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"martin_rescan_helper.lib"];
}

@end
