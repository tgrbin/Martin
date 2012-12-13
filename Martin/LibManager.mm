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
#import <cstdio>
#import <vector>
#import <ftw.h>

using namespace std;

@interface LibManager ()
@property (atomic, assign) BOOL nowSearching;
@property (atomic, strong) NSString *pendingSearchQuery;
@end

@implementation LibManager

+ (LibManager *)sharedManager {
  static LibManager *o = nil;
  if (o == nil) o = [LibManager new];
  return o;
}

- (id)init {
  if (self = [super init]) {
    previousSearchQuery = @"";
    [self loadLibrary];
  }
  return self;
}

static const int kBuffSize = 1<<16;
static char lineBuff[kBuffSize];
static char pathBuff[kBuffSize];

static vector<int> needsRescan;
static vector<int> emptyFolders;
static int numberOfSongsFound;

static vector<int> folderStack;
static int lineNumber;
static int lastSongPos;
static int lastFolderLevel;
static BOOL wasLastItemFolder;
static FILE *walkFile;

- (void)loadLibrary {
  @autoreleasepool {
    [[Tree sharedTree] clearTree];
    
    FILE *f = fopen(toCstr([self libPath]), "r");
    if (f == NULL) return;
    
    vector<int> treePath(1, 0);
    
    while(fgets(lineBuff, kBuffSize, f) != NULL) {
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
        
        fgets(lineBuff, kBuffSize, f);
        sscanf(lineBuff, "%d", &songData->inode);

        fgets(lineBuff, kBuffSize, f);
        sscanf(lineBuff, "%d", &songData->lastModified);
        
        fgets(lineBuff, kBuffSize, f);
        NSString *fileName = [self stringFromBuff:lineBuff];

        fgets(lineBuff, kBuffSize, f);
        sscanf(lineBuff, "%d", &songData->lengthInSeconds);
        
        for (int i = 0; i < kNumberOfTags; ++i) {
          fgets(lineBuff, kBuffSize, f);
          tagsSet(songData->tags, i, lineBuff);
        }
        
        [[Tree sharedTree] addChild:fileName parent:treePath.back() song:song];
        [[Tree sharedTree] addToSongByInodeMap:song inode:songData->inode];
        
        fgets(lineBuff, kBuffSize, f); // skip '}'
      } else {
        if (treePath.size() > 1) {
          treePath.pop_back();
        }
        
        NSString *folderName = [self stringFromBuff:lineBuff];
        fgets(lineBuff, kBuffSize, f);
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
  int len = (int)strlen(buff);
  if (buff[len-1] == '\n') buff[len-1] = 0;
  return [NSString stringWithCString:buff encoding:NSUTF8StringEncoding];
}

- (void)rescanLibraryWithProgressBlock:(void (^)(int))progressBlock {
  __block id selfRef = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    if ([selfRef walkLibrary] == -1) progressBlock(-1);
    else {
      [selfRef rescanSongs:progressBlock];
      [selfRef loadLibrary];
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kLibManagerRescanedLibraryNotification object:nil];
    });
  });
}

- (void)rescanSongs:(void (^)(int))block {
  @autoreleasepool {
    int songsToRescan = (int) needsRescan.size() - 1;

    block(numberOfSongsFound);
    block(songsToRescan);
    
    FILE *f = fopen(toCstr([self rescanPath]), "r");
    FILE *g = fopen(toCstr([self rescanHelperPath]), "w");
    int emptyFolderCount = 0, nextEmptyFolderIndex = 0;
    int songStart = -1, lastBaseURLLineNumber = -2;
    int nextRescanIndex = 0;
    ID3Reader *id3 = nil;
    BOOL id3Failed = NO;
    int lastSentPercentage = -1, songsScanned = 0;
    vector<int> pathComponents;
    
    for (int ln = 0; fgets(lineBuff, kBuffSize, f) != NULL; ++ln) {
      lineBuff[strlen(lineBuff) - 1] = 0; // remove newline
      
      BOOL writeThrough = YES;
      
      if (lineBuff[0] == '}') {
        songStart = -1;
        if (id3) {
          int percentage = (double)++songsScanned / songsToRescan * 100;
          if (percentage != lastSentPercentage) {
            block(lastSentPercentage = percentage);
          }
          [id3 release];
          id3 = nil;
        }
      } else if (songStart != -1) {
        int fieldPos = ln - songStart;
        if (fieldPos == 3 && ln == needsRescan[nextRescanIndex]) {
          int oldLen = (int) strlen(pathBuff);
          strcat(pathBuff, "/");
          strcat(pathBuff, lineBuff);
          id3 = [[ID3Reader alloc] initWithFile:toString(pathBuff)];
          if (id3 == nil) {
            NSLog(@"id3 read failed for: %s", pathBuff);
            id3Failed = YES;
          } else {
            id3Failed = NO;
          }
          pathBuff[oldLen] = 0;
          ++nextRescanIndex;
        } else if (fieldPos > 3 && (id3 != nil || id3Failed)) {
          if (fieldPos == 4) {
            sprintf(lineBuff, "%d", id3Failed? 0: id3.lengthInSeconds);
          } else {
            if (id3Failed) {
              strcpy(lineBuff, "/");
            } else {
              NSString *tagVal = [id3 tag:[Tags tagNameForIndex:fieldPos-5]];
              if (tagVal == nil || tagVal.length == 0) lineBuff[0] = 0;
              else strcpy(lineBuff, toCstr(tagVal));
            }
          }
        }
      } else if (lineBuff[0] == '+') {
        if (ln == emptyFolders[nextEmptyFolderIndex]) {
          ++nextEmptyFolderIndex;
          ++emptyFolderCount;
          writeThrough = NO;
        } else {
          pathComponents.push_back((int)strlen(pathBuff));
          strcat(pathBuff, "/");
          strcat(pathBuff, lineBuff + 2);
        }
      } else if (lineBuff[0] == '-') {
        if (emptyFolderCount > 0) {
          --emptyFolderCount;
          writeThrough = NO;
        } else {
          pathBuff[pathComponents.back()] = 0;
          pathComponents.pop_back();
        }
      } else if (lineBuff[0] == '{') {
        songStart = ln;
      } else {
        if (lastBaseURLLineNumber != ln-1) {
          strcpy(pathBuff, lineBuff);
          lastBaseURLLineNumber = ln;
        }
      }
      
      if (writeThrough) {
        fprintf(g, "%s\n", lineBuff);
      }
    }
    
    fclose(f);
    fclose(g);
    
    unlink(toCstr([self libPath]));
    rename(toCstr([self rescanHelperPath]), toCstr([self libPath]));
  }
}

static const char *toCstr(NSString *s) {
  return [s cStringUsingEncoding:NSUTF8StringEncoding];
}

static NSString *toString(const char *s) {
  return [NSString stringWithCString:s encoding:NSUTF8StringEncoding];
}

- (int)walkLibrary {
  vector<NSString *> libraryDisplayNames;
  vector<NSString *> libraryPaths;
  for (LibraryFolder *lf in [LibraryFolder libraryFolders]) {
    libraryDisplayNames.push_back([lf.treeDisplayName retain]);
    libraryPaths.push_back([lf.folderPath retain]);
  }

  walkFile = fopen(toCstr([self rescanPath]), "w");
  lineNumber = 0;
  lastSongPos = 0;
  numberOfSongsFound = 0;
  folderStack.clear();
  emptyFolders.clear();
  needsRescan.clear();
  
  for (int i = 0; i < libraryPaths.size(); ++i) {
    fprintf(walkFile, "%s\n", toCstr(libraryPaths[i]));
    fprintf(walkFile, "%s\n", toCstr(libraryDisplayNames[i]));
    lineNumber += 2;
    
    lastFolderLevel = 0;
    wasLastItemFolder = NO;

    if (nftw(toCstr(libraryPaths[i]), ftw_callback, 512, 0) != 0) {
      fclose(walkFile);
      return -1;
    }
    
    for (int j = 1; j < lastFolderLevel; ++j) {
      fprintf(walkFile, "-\n");
      ++lineNumber;
      
      if (folderStack.back() > lastSongPos) emptyFolders.push_back(folderStack.back());
      folderStack.pop_back();
    }
  }
  
  fclose(walkFile);
  emptyFolders.push_back(-1);
  needsRescan.push_back(-1);
  for (int i = 0; i < libraryPaths.size(); ++i) {
    [libraryPaths[i] release];
    [libraryDisplayNames[i] release];
  }
  return 0;
}

static BOOL isExtensionAcceptable(const char *str) {
  int len = (int)strlen(str);
  return strcmp(str + len - 4, ".mp3") == 0;
}

static int ftw_callback(const char *filename, const struct stat *stat_struct, int flags, struct FTW *ftw_struct) {
  int currentLevel = ftw_struct->level;
  BOOL isFolder = (flags == FTW_D);
  const char *basename = filename + ftw_struct->base;
  
  if (currentLevel == 0) return 0;
  
  if (currentLevel <= lastFolderLevel) { // leaving folder
    int cnt = (lastFolderLevel-currentLevel) + (wasLastItemFolder == YES);
    for (int i = 0; i < cnt; ++i) {
      fprintf(walkFile, "-\n");
      ++lineNumber;
      if (folderStack.back() > lastSongPos) emptyFolders.push_back(folderStack.back());
      folderStack.pop_back();
    }
  }
  
  if (isFolder) { // entering directory
    fprintf(walkFile, "+ %s\n", basename);
    folderStack.push_back(lineNumber++);
  } else if (isExtensionAcceptable(filename)) {
    ++numberOfSongsFound;
    lastSongPos = lineNumber;
    
    int inode = (int)stat_struct->st_ino;
    int lastModified = (int) stat_struct->st_mtimespec.tv_sec;
    int song = [[Tree sharedTree] songByInode:inode];
    struct LibrarySong *songData = (song == -1)? NULL: [[Tree sharedTree] songDataForP:song];
    
    fprintf(walkFile, "{\n%d\n%d\n%s\n", inode, lastModified, basename);
    lineNumber += 4;
    
    if (song == -1 || songData->lastModified != lastModified) {
      needsRescan.push_back(lineNumber - 1);
      for (int i = 0; i <= kNumberOfTags; ++i) fprintf(walkFile, "\n");
      lineNumber += kNumberOfTags + 1;
    } else {
      fprintf(walkFile, "%d\n", songData->lengthInSeconds);
      ++lineNumber;
      for (int i = 0; i < kNumberOfTags; ++i) {
        fprintf(walkFile, "%s\n", songData->tags[i]);
        ++lineNumber;
      }
    }
    
    fprintf(walkFile, "}\n");
    ++lineNumber;
  }
  
  lastFolderLevel = currentLevel;
  wasLastItemFolder = isFolder;

  return 0;
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
//      queryWords.clear();
//      for (NSString *q in [currentQuery componentsSeparatedByString:@" "]) {
//        NSString *s = [q stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//        if (s.length > 0) queryWords.push_back(s);
//      }
//      
//      queryHits.resize(queryWords.size(), false);
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
//  for (int i = 0; i < queryWords.size(); ++i) {
//    if (queryHits[i]) continue;
//    if ([node.name rangeOfString:queryWords[i] options:NSCaseInsensitiveSearch].location == NSNotFound) {
//      BOOL foundInTag = NO;
//      
//      if ([node isKindOfClass:[TreeLeaf class]]) {
//        NSDictionary *d = ((TreeLeaf *)node).song.tagsDictionary;
//        for (id key in d) {
//          NSString *val = d[key];
//          if ([val rangeOfString:queryWords[i] options:NSCaseInsensitiveSearch].location != NSNotFound) {
//            foundInTag = YES;
//            break;
//          }
//        }
//      }
//        
//      if (!foundInTag) continue;
//    }
//    
//    queryHits[i] = true;
//    ++nHit;
//    modified.push_back(i);
//  }
//  
//  BOOL was2 = (node.searchState == 2);
//  node.searchState = 0;
//  
//  if (nHit == queryWords.size()) {
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
//    --nHit;
//    queryHits[modified[i]] = false;
//  }
//  
//  return node.searchState;
}

#pragma mark - lib files

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
