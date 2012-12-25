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
#import "FolderWatcher.h"

#import <algorithm>
#import <cstdio>
#import <vector>
#import <set>
#import <ftw.h>

using namespace std;

@implementation LibManager

static const int kBuffSize = 1<<16;
static char lineBuff[kBuffSize];
static char pathBuff[kBuffSize];

static vector<int> needsRescan;
static int numberOfSongsFound;

static int lineNumber;
static int lastFolderLevel;
static BOOL wasLastItemFolder;
static FILE *walkFile;

static set<uint64> pathsToRescan[2];

+ (void)initLibrary {
  loadLibrary();
}

+ (void)rescanAll {
  static struct stat statBuff;
  
  dispatch_sync(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLibraryRescanStartedNotification object:nil];
  });

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    initWalk();
    
    BOOL watchingFolders = [FolderWatcher sharedWatcher].enabled;
    for (NSString *s in [LibraryFolder libraryFolders]) {
      const char *folder = [s UTF8String];
      
      if (watchingFolders) {
        stat(folder, &statBuff);
        
        int node = [Tree nodeByInode:statBuff.st_ino];
        if (node == -1) walkFolder(folder);
        else walkTreeNode(node);
      } else {
        walkFolder(folder);
      }
    }
  
    endWalk();
    rescanID3s();
  });
}

+ (void)rescanPaths:(NSArray *)paths recursively:(NSArray *)recursively {
  for (int i = 0; i < paths.count; ++i) {
    [paths[i] getCString:pathBuff maxLength:kBuffSize encoding:NSUTF8StringEncoding];
    pathsToRescan[ [recursively[i] boolValue] ].insert( folderHash(pathBuff) );
  }
  
  dispatch_sync(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLibraryRescanStartedNotification object:nil];
  });
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    initWalk();
    walkTreeNode(0);
    endWalk();
    rescanID3s();
  });
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

#pragma mark - helper functions

static void walkPrint(const char *format, ...) {
  va_list vl;
  va_start(vl, format);
  vfprintf(walkFile, format, vl);
  va_end(vl);
  fprintf(walkFile, "\n");
  ++lineNumber;
}

static uint64 folderHash(const char *f) {
  unsigned long hash = 5381;
  for (int c; (c = *f++); hash = ((hash << 5) + hash) + c);
  return hash;
}

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
  numberOfSongsFound = 0;
  needsRescan.clear();
}

static void endWalk() {
  fclose(walkFile);
  pathsToRescan[0].clear();
  pathsToRescan[1].clear();
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

static BOOL rescanSong(FILE *f) {
  ID3Reader *id3 = [[ID3Reader alloc] initWithFile:@(pathBuff)];

  if (id3 == nil) {
    return NO;
  } else {
    fprintf(f, "%d\n", id3.lengthInSeconds);
    for (int i = 0; i < kNumberOfTags; ++i) {
      NSString *val = [id3 tag:[Tags tagNameForIndex:i]];
      fprintf(f, "%s\n", val? [val UTF8String]: "");
    }
    
    [id3 release];
    return YES;
  }
}

static void rescanID3s() {
  @autoreleasepool {
    FILE *f = fopen(rescanPath(), "r");
    FILE *g = fopen(rescanHelperPath(), "w");
    
    int linesToForward = 0;
    int nextRescanIndex = 0;
    vector<size_t> pathComponents;
    
    needsRescan.push_back(-1);
    
    pathBuff[0] = 0;
    
    for (int ln = 0; fgets(lineBuff, kBuffSize, f) != NULL; ++ln) {
      lineBuff[strlen(lineBuff) - 1] = 0; // remove newline
      
      if (linesToForward > 0) {
        --linesToForward;
      } else {
        if (ln == needsRescan[nextRescanIndex] + 3) {
          
          if (rescanSong(g)) {
            for (int i = 0; i < 1 + kNumberOfTags; ++i, ++ln) fgets(lineBuff, kBuffSize, f);
          } else {
            NSLog(@"id3 read failed for: %s", pathBuff);
            linesToForward = 1 + kNumberOfTags;
          }
          
          // report status!
          
        } else {
          char firstChar = lineBuff[0];
          if (firstChar == '+' || firstChar == '{') {
            pathComponents.push_back(strlen(pathBuff));
            strcat(pathBuff, "/");
            strcat(pathBuff, lineBuff + 2);
            
            if (firstChar == '+') {
              linesToForward = 1;
            } else {
              linesToForward = (ln == needsRescan[nextRescanIndex])? 2: 3 + kNumberOfTags;
            }
          } else if (firstChar == '-') {
            pathBuff[pathComponents.back()] = 0;
            pathComponents.pop_back();
          }
        }
      }
      
      fprintf(g, "%s\n", lineBuff);
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

#pragma mark - walking

static int ftw_callback(const char *filename, const struct stat *stat_struct, int flags, struct FTW *ftw_struct) {
  int currentLevel = ftw_struct->level;
  BOOL isFolder = (flags == FTW_D);
  ino_t inode = stat_struct->st_ino;
  const char *basename = filename + ftw_struct->base;
  
  if (currentLevel <= lastFolderLevel) { // leaving folder
    int cnt = (lastFolderLevel-currentLevel) + (wasLastItemFolder == YES);
    for (int i = 0; i < cnt; ++i) walkPrint("-");
  }
  
  if (isFolder) {
    // library root folders output full path
    walkPrint("+ %s", (currentLevel == 0)? filename: basename);
    walkPrint("%d", inode);
  } else if (isExtensionAcceptable(filename)) {
    ++numberOfSongsFound;
    
    int lastModified = (int) stat_struct->st_mtimespec.tv_sec;
    int song = [Tree songByInode:inode];
    struct LibrarySong *songData = (song == -1)? NULL: [Tree songDataForP:song];
    
    walkPrint("{ %s", basename);
    walkPrint("%d", inode);
    walkPrint("%d", lastModified);
    
    if (song == -1 || songData->lastModified != lastModified) {
      needsRescan.push_back(lineNumber - 3);
      for (int i = 0; i <= kNumberOfTags; ++i) walkPrint("");
    } else {
      walkPrint("%d", songData->lengthInSeconds);
      for (int i = 0; i < kNumberOfTags; ++i) walkPrint("%s", songData->tags[i]);
    }
    
    walkPrint("}");
  }
  
  lastFolderLevel = currentLevel;
  wasLastItemFolder = isFolder;
  
  return 0;
}

static void walkFolder(const char *folder) {
  lastFolderLevel = 0;
  wasLastItemFolder = NO;
  
  nftw(folder, ftw_callback, 512, 0);
  
  for (int i = 0; i < lastFolderLevel; ++i) walkPrint("-");
}

static void walkTreeNode(int p_node) {
  
}

static void rescanLibrary() {
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

@end
