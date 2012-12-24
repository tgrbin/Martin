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
#import "TreeNode.h"

#import <algorithm>
#import <cstdio>
#import <vector>
#import <ftw.h>

using namespace std;

@implementation LibManager

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

static int numberOfPathsToRescan;
static char **pathsToRescan;

+ (void)initLibrary {
  loadLibrary();
}

+ (void)rescanPaths:(NSArray *)paths recursively:(NSArray *)recursively {
  
}

//+ (void)rescanLibrary {
//  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//    walkLibrary();
//    rescanID3s();
//  });
//}
//
//+ (void)rescanTreeNodes:(NSArray *)treeNodes {
//  [self rescanFilteredNodes:[Tree filterRootElements:treeNodes]];
//}
//
//+ (void)rescanPaths:(NSArray *)paths {
//  NSMutableArray *arr = [NSMutableArray arrayWithArray:paths];
//  [arr sortUsingSelector:@selector(compare:)];
//  
//  NSMutableArray *purged = [[NSMutableArray alloc] init];
//  int currentRoot = -1;
//  for (int i = 0; i < arr.count; ++i) {
//    if (currentRoot == -1 || [arr[i] hasPrefix:arr[currentRoot]] == NO) {
//      currentRoot = i;
//      [purged addObject:arr[i]];
//    }
//  }
//  
//  [self rescanFilteredNodes:[Tree nodesForPaths:purged]];
//  [purged release];
//}
//
//// no node in nodes is a child of another one
//+ (void)rescanFilteredNodes:(NSArray *)nodes {
//  numberOfPathsToRescan = (int)nodes.count;
//  pathsToRescan = (char**) malloc(numberOfPathsToRescan * sizeof(char*));
//  for (int i = 0; i < numberOfPathsToRescan; ++i) {
//    NSString *path = [Tree fullPathForNode:[nodes[i] intValue]];
//    pathsToRescan[i] = (char*) malloc(kBuffSize);
//    [path getCString:pathsToRescan[i] maxLength:kBuffSize encoding:NSUTF8StringEncoding];
//  }
//  
//  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//    rescanFolders();
//    rescanID3s();
//    dispatch_async(dispatch_get_main_queue(), ^{
//      for (int i = 0; i < numberOfPathsToRescan; ++i) free(pathsToRescan[i]);
//      free(pathsToRescan);
//    });
//  });
//}

#pragma mark - functions

static NSString *stringFromBuff(char *buff) {
  size_t len = strlen(buff);
  if (len > 0 && buff[len-1] == '\n') buff[len-1] = 0;
  return [NSString stringWithCString:buff encoding:NSUTF8StringEncoding];
}

static const char *libPath() {
  static NSString *path = nil;
  if (path == nil) path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"martin.lib"] retain];
  return [path cStringUsingEncoding:NSUTF8StringEncoding];
}

static const char *rescanPath() {
  static NSString *path = nil;
  if (path == nil) path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"martin_rescan.lib"] retain];
  return [path cStringUsingEncoding:NSUTF8StringEncoding];
}

static const char *rescanHelperPath() {
  static NSString *path = nil;
  if (path == nil) path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"martin_rescan_helper.lib"] retain];
  return [path cStringUsingEncoding:NSUTF8StringEncoding];
}

static void initWalk() {
  walkFile = fopen(rescanPath(), "w");
  lineNumber = 0;
  lastSongPos = 0;
  numberOfSongsFound = 0;
  folderStack.clear();
  emptyFolders.clear();
  needsRescan.clear();
}

static const char *toCstr(NSString *s) {
  return [s cStringUsingEncoding:NSUTF8StringEncoding];
}

static NSString *toString(const char *s) {
  return [NSString stringWithCString:s encoding:NSUTF8StringEncoding];
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
    int song = [Tree songByInode:inode];
    struct LibrarySong *songData = (song == -1)? NULL: [Tree songDataForP:song];
    
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

#pragma mark - load library

static int readTreeNode(FILE *f, int parent) {
  int node = [Tree addChild:lineBuff+2 parent:parent];
  fscanf(f, "%d\n", &[Tree treeNodeDataForP:node]->inode);
  [Tree addToNodeByInodeMap:node];
  return node;
}

static void loadLibrary() {
  @autoreleasepool {
    [Tree clearTree];
    
    FILE *f = fopen(libPath(), "r");
    if (f == NULL) return;
    
    vector<int> treePath(1, 0);
    
    while(fgets(lineBuff, kBuffSize, f) != NULL) {
      char firstChar = lineBuff[0];
      
      if (firstChar == 0) break;
      
      if (firstChar == '+') {
        
        treePath.push_back( readTreeNode(f, treePath.back()) );
        
      } else if (firstChar == '-') {
        
        treePath.pop_back();
        
      } else if (firstChar == '{') {
        int node = readTreeNode(f, treePath.back());
        struct LibrarySong *songData = [Tree newSong];
        
        songData->p_treeLeaf = node;
        [Tree treeNodeDataForP:node]->p_song = node;
        
        fscanf(f, "%d\n", &songData->lastModified);
        fscanf(f, "%d\n", &songData->lengthInSeconds);
        for (int i = 0; i < kNumberOfTags; ++i) {
          fgets(lineBuff, kBuffSize, f);
          tagsSet(songData->tags, i, lineBuff);
        }
        
        fscanf(f, "}\n");
      }
    }
    
    fclose(f);
  }
}

#pragma mark - rescan songs

static void rescanID3s() {
  @autoreleasepool {
    int songsToRescan = (int) needsRescan.size();
    
    FILE *f = fopen(rescanPath(), "r");
    FILE *g = fopen(rescanHelperPath(), "w");
    int emptyFolderCount = 0, nextEmptyFolderIndex = 0;
    int songStart = -1, lastBaseURLLineNumber = -2;
    int nextRescanIndex = 0;
    ID3Reader *id3 = nil;
    BOOL id3Failed = NO;
    int lastSentPercentage = -1, songsScanned = 0;
    vector<size_t> pathComponents;
    
    emptyFolders.push_back(-1);
    needsRescan.push_back(-1);
    
    for (int ln = 0; fgets(lineBuff, kBuffSize, f) != NULL; ++ln) {
      lineBuff[strlen(lineBuff) - 1] = 0; // remove newline
      
      BOOL writeThrough = YES;
      char firstChar = lineBuff[0];
      
      if (firstChar == '}') {
        songStart = -1;
        if (id3) {
          int percentage = (double)++songsScanned / songsToRescan * 100;
          if (percentage != lastSentPercentage) {
            //            block(lastSentPercentage = percentage);
          }
          [id3 release];
          id3 = nil;
        }
      } else if (songStart != -1) {
        int fieldPos = ln - songStart;
        if (fieldPos == 3 && ln == needsRescan[nextRescanIndex]) {
          size_t oldLen = strlen(pathBuff);
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
      } else if (firstChar == '+') {
        if (ln == emptyFolders[nextEmptyFolderIndex]) {
          ++nextEmptyFolderIndex;
          ++emptyFolderCount;
          writeThrough = NO;
        } else {
          pathComponents.push_back(strlen(pathBuff));
          strcat(pathBuff, "/");
          strcat(pathBuff, lineBuff + 2);
        }
      } else if (firstChar == '-') {
        if (emptyFolderCount > 0) {
          --emptyFolderCount;
          writeThrough = NO;
        } else {
          pathBuff[pathComponents.back()] = 0;
          pathComponents.pop_back();
        }
      } else if (firstChar == '{') {
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
    
    unlink(libPath());
    rename(rescanHelperPath(), libPath());
    
    loadLibrary();
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kLibraryRescanFinishedNotification object:nil];
    });
  }
}

static BOOL startWalkingInRescan(FILE *f, BOOL isLibaryPath, int pathIndex) {
  lastFolderLevel = 0;
  wasLastItemFolder = NO;
  nftw(pathsToRescan[pathIndex], ftw_callback, 512, 0);
  for (int i = isLibaryPath? 1: 0; i < lastFolderLevel; ++i) {
    fprintf(walkFile, "-\n");
    ++lineNumber;
  }
  
  BOOL inSong = NO;
  for (int depth = 0;;) {
    if (isLibaryPath == NO && depth == -1) break;
    
    if (fgets(lineBuff, kBuffSize, f) == NULL) return NO;
    
    if (isLibaryPath == YES && inSong == NO && depth == 0 && lineBuff[0] == '/') break;
    
    if (lineBuff[0] == '{') inSong = YES;
    if (lineBuff[0] == '}') inSong = NO;
    if (inSong) continue;
    if (lineBuff[0] == '+') ++depth;
    if (lineBuff[0] == '-') --depth;
  }
  
  return YES;
}

static void rescanFolders() {
  @autoreleasepool {
    initWalk();
    
    FILE *f = fopen(libPath(), "r");
    vector<size_t> slashPositions;
    BOOL withinSong = NO;
    BOOL justRescannedLibraryPath = NO;
    
    int nextPathIndex = 0;
    
    for (pathBuff[0] = 0;;) {
      if (justRescannedLibraryPath == NO && fgets(lineBuff, kBuffSize, f) == NULL) break;
      
      justRescannedLibraryPath = NO;
      
      char firstChar = lineBuff[0];
      
      lineBuff[strlen(lineBuff)-1] = 0; // remove newline
      
      if (firstChar == '+') {
        strcat(pathBuff, lineBuff+2);
        size_t len = strlen(pathBuff);
        slashPositions.push_back(len);
        
        if (nextPathIndex != numberOfPathsToRescan && strcmp(pathsToRescan[nextPathIndex], pathBuff) == 0) {
          fprintf(walkFile, "%s\n", lineBuff);
          ++lineNumber;
          
          startWalkingInRescan(f, NO, nextPathIndex++);
          
          slashPositions.pop_back();
          pathBuff[slashPositions.back() + 1] = 0;
          continue;
        }
        
        pathBuff[len] = '/';
        pathBuff[len+1] = 0;
      } else if (firstChar == '-') {
        slashPositions.pop_back();
        pathBuff[slashPositions.back() + 1] = 0;
      } else if (firstChar == '{') {
        withinSong = YES;
      } else if (firstChar == '}') {
        withinSong = NO;
      } else if (withinSong == NO) { // new base url
        BOOL rescanWholeLibraryFolder = (nextPathIndex != numberOfPathsToRescan && strcmp(pathsToRescan[nextPathIndex], lineBuff) == 0);
        
        strcpy(pathBuff, lineBuff);
        strcat(pathBuff, "/");
        slashPositions.clear();
        slashPositions.push_back(strlen(pathBuff)-1);
        fprintf(walkFile, "%s\n", lineBuff);
        fgets(lineBuff, kBuffSize, f);
        fprintf(walkFile, "%s", lineBuff);
        lineNumber += 2;
        
        if (rescanWholeLibraryFolder) {
          if (startWalkingInRescan(f, YES, nextPathIndex++) == NO) break;
          justRescannedLibraryPath = YES;
        }

        continue;
      }
      
      fprintf(walkFile, "%s\n", lineBuff);
      ++lineNumber;
    }
    
    fclose(walkFile);
    fclose(f);
    
    rescanID3s();
  }
}

static void walkLibrary() {
  vector<NSString *> libraryDisplayNames;
  vector<NSString *> libraryPaths;
  for (LibraryFolder *lf in [LibraryFolder libraryFolders]) {
    libraryDisplayNames.push_back([lf.treeDisplayName retain]);
    libraryPaths.push_back([lf.folderPath retain]);
  }
 
  initWalk();
  
  for (int i = 0; i < libraryPaths.size(); ++i) {
    fprintf(walkFile, "%s\n", toCstr(libraryPaths[i]));
    fprintf(walkFile, "%s\n", toCstr(libraryDisplayNames[i]));
    lineNumber += 2;
    
    lastFolderLevel = 0;
    wasLastItemFolder = NO;

    nftw(toCstr(libraryPaths[i]), ftw_callback, 512, 0);
    
    for (int j = 1; j < lastFolderLevel; ++j) {
      fprintf(walkFile, "-\n");
      ++lineNumber;
      
      if (folderStack.back() > lastSongPos) emptyFolders.push_back(folderStack.back());
      folderStack.pop_back();
    }
  }
  
  fclose(walkFile);
  for (int i = 0; i < libraryPaths.size(); ++i) {
    [libraryPaths[i] release];
    [libraryDisplayNames[i] release];
  }
}

@end
