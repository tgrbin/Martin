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
#import <dirent.h>

using namespace std;

@implementation LibManager

static const int kBuffSize = 1<<16;
static char lineBuff[kBuffSize];
static char pathBuff[kBuffSize];

static vector<int> needsRescan;
static int numberOfSongsFound;


static int lastFolderLevel;
static BOOL wasLastItemFolder;
static BOOL onRootLevel;
static int lineNumber;
static FILE *walkFile;

static set<uint64> pathsToRescan[2];

+ (void)initLibrary {
  loadLibrary();
}

+ (void)rescanAll {
  static struct stat statBuff;
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kLibraryRescanStartedNotification object:nil];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    initWalk();
    
    BOOL watchingFolders = [FolderWatcher sharedWatcher].enabled;
    for (NSString *s in [LibraryFolder libraryFolders]) {
      const char *folder = [s UTF8String];
      
      if (watchingFolders) {
        stat(folder, &statBuff);
        int node = [Tree nodeByInode:statBuff.st_ino];
        if (node == -1) walkFolder(folder, YES);
        else {
          if ([Tree treeNodeDataForP:node]->p_parent > 0) {
            strcpy(pathBuff, folder);
            *strrchr(pathBuff, '/') = 0;
          }
          walkTreeNode(node, YES);
        }
      } else {
        walkFolder(folder, YES);
      }
    }
    
    endWalk();
    rescanID3s();
  });
}

+ (void)rescanPaths:(NSArray *)paths recursively:(NSArray *)recursively {
  for (int i = 0; i < paths.count; ++i) {
    [paths[i] getCString:pathBuff maxLength:kBuffSize encoding:NSUTF8StringEncoding];
    size_t pathLen = strlen(pathBuff);
    if (pathBuff[pathLen-1] == '/') pathBuff[pathLen-1] = 0;
    pathsToRescan[ [recursively[i] boolValue] ].insert( folderHash(pathBuff) );
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLibraryRescanStartedNotification object:nil];
  });
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    initWalk();
    walkTreeNode(0, YES);
    endWalk();
    rescanID3s();
  });
}

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
  pathBuff[0] = 0;
}

static void endWalk() {
  fclose(walkFile);
  pathsToRescan[0].clear();
  pathsToRescan[1].clear();
  pathBuff[0] = 0;
}

static const char *toCstr(NSString *s) {
  return [s cStringUsingEncoding:NSUTF8StringEncoding];
}

static NSString *toString(const char *s) {
  return [NSString stringWithCString:s encoding:NSUTF8StringEncoding];
}

static BOOL isExtensionAcceptable(const char *str) {
  int len = (int)strlen(str);
  if (strcasecmp(str + len - 4, ".mp3") == 0) return YES;
  if (strcasecmp(str + len - 4, ".m4a") == 0) return YES;
  return NO;
}

#pragma mark - load library

static int readTreeNode(FILE *f, int parent) {
  int node = [Tree addChild:lineBuff+2 parent:parent];
  fscanf(f, "%lld\n", &[Tree treeNodeDataForP:node]->inode);
  [Tree addToNodeByInodeMap:node];
  return node;
}

static void loadLibrary() {
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
      int song = [Tree newSong];
      struct LibrarySong *songData = [Tree songDataForP:song];
      
      songData->p_treeLeaf = node;
      [Tree treeNodeDataForP:node]->p_song = song;
      
      fscanf(f, "%ld", &songData->lastModified);
      fscanf(f, "%d", &songData->lengthInSeconds);
      fgets(lineBuff, kBuffSize, f); // read just the newline
      for (int i = 0; i < kNumberOfTags; ++i) {
        fgets(lineBuff, kBuffSize, f);
        tagsSet(songData->tags, i, lineBuff);
      }
    }
  }
  
  fclose(f);
}

#pragma mark - rescan songs

static BOOL rescanSong(FILE *f) {
  ID3Reader *id3 = [[ID3Reader alloc] initWithFile:@(pathBuff)];

  if (id3 == nil) {
    fprintf(f, "0\n");
    for (int i = 0; i < kNumberOfTags; ++i) fprintf(f, "\n");
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
    
    needsRescan.push_back(-5);
    
    for (int ln = 0; fgets(lineBuff, kBuffSize, f) != NULL; ++ln) {
      lineBuff[strlen(lineBuff) - 1] = 0; // remove newline
      
      if (linesToForward > 0) {
        --linesToForward;
      } else {
        if (ln == needsRescan[nextRescanIndex] + 3) {
          if (rescanSong(g) == NO) NSLog(@"id3 read failed for: %s", pathBuff);
          for (int i = 0; i < kNumberOfTags; ++i, ++ln) fgets(lineBuff, kBuffSize, f);
          
          // TODO: report status!
          
          ++nextRescanIndex;
          continue;
        } else {
          char firstChar = lineBuff[0];
          if (firstChar == '+' || firstChar == '{') {
            pathComponents.push_back(strlen(pathBuff));
            strcat(pathBuff, lineBuff + 2);
            
            if (firstChar == '+') {
              strcat(pathBuff, "/");
              linesToForward = 1;
            } else {
              linesToForward = (ln == needsRescan[nextRescanIndex])? 2: 3 + kNumberOfTags;
            }
          } else if (firstChar == '-' || firstChar == '}') {
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
// TODO: unlink extra files
//    unlink(rescanHelperPath());
//    unlink(rescanPath());
    
    loadLibrary();
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kLibraryRescanFinishedNotification object:nil];
    });
  }
}

#pragma mark - walking

static void walkSong(const char *name, int p_song, const struct stat *statBuff) {
  time_t lastModified = statBuff->st_mtimespec.tv_sec;
  
  walkPrint("{ %s", name);
  walkPrint("%lld", statBuff->st_ino);
  walkPrint("%ld", lastModified);
  
  struct LibrarySong *song = (p_song == -1)? NULL: [Tree songDataForP:p_song];
  
  if (p_song == -1 || song->lastModified != lastModified) {
    needsRescan.push_back(lineNumber - 3);
    for (int i = 0; i <= kNumberOfTags; ++i) walkPrint("");
  } else {
    walkPrint("%d", song->lengthInSeconds);
    for (int i = 0; i < kNumberOfTags; ++i) walkPrint("%s", song->tags[i]);
  }
  
  walkPrint("}");
}

static int ftw_callback(const char *filename, const struct stat *stat_struct, int flags, struct FTW *ftw_struct) {
  int currentLevel = ftw_struct->level;
  BOOL isFolder = (flags == FTW_D);
  ino_t inode = stat_struct->st_ino;
  const char *basename = filename + ftw_struct->base;
  
  if (currentLevel <= lastFolderLevel) { // we left some folders
    int cnt = (lastFolderLevel-currentLevel) + (wasLastItemFolder == YES);
    for (int i = 0; i < cnt; ++i) walkPrint("-");
  }
  
  if (isFolder) {
    walkPrint("+ %s", (currentLevel == 0 && onRootLevel)? filename: basename);
    walkPrint("%d", inode);
  } else if (isExtensionAcceptable(filename)) {
    ++numberOfSongsFound;
    walkSong(basename, [Tree songByInode:inode], stat_struct);
  }
  
  lastFolderLevel = currentLevel;
  wasLastItemFolder = isFolder;
  
  return 0;
}

static void walkFolder(const char *folder, BOOL _onRootLevel) {
  lastFolderLevel = 0;
  wasLastItemFolder = NO;
  onRootLevel = _onRootLevel;
  
  nftw(folder, ftw_callback, 512, 0);
  
  for (int i = 0; i < lastFolderLevel; ++i) walkPrint("-");
}

static void walkTreeNode(int, BOOL);

static void walkFolderNonRecursively(BOOL _onRootLevel) {
  static struct stat statBuff;
  
  DIR *dir = opendir(pathBuff);
  size_t pathLen = strlen(pathBuff);
  
  for (struct dirent *entry; (entry = readdir(dir)) != NULL;) {
    if (entry->d_name[0] == '.') {
      if (entry->d_name[1] == 0) {
        walkPrint("+ %s", _onRootLevel? pathBuff: strrchr(pathBuff, '/') + 1);
        walkPrint("%lld", entry->d_ino);
      }
      continue;
    }
    
    int node = [Tree nodeByInode:entry->d_ino];
    strcat(pathBuff, "/");
    strcat(pathBuff, entry->d_name);
    
    if (entry->d_type == DT_DIR) {
      if (node == -1) {
        walkFolder(pathBuff, NO);
      } else {
        [Tree setName:entry->d_name forNode:node];
        pathBuff[pathLen] = 0;
        walkTreeNode(node, NO);
      }
    } else if (entry->d_type == DT_REG && isExtensionAcceptable(entry->d_name)) {
      stat(pathBuff, &statBuff);
      
      int p_song = (node == -1)? -1: [Tree treeNodeDataForP:node]->p_song;
      walkSong(entry->d_name, p_song, &statBuff);
    }
    
    pathBuff[pathLen] = 0;
  }
  
  closedir(dir);
  walkPrint("-");
}

static void dumpSong(struct TreeNode *node) {
  struct LibrarySong *song = [Tree songDataForP:node->p_song];
  
  walkPrint("{ %s", node->name);
  walkPrint("%lld", node->inode);
  walkPrint("%ld", song->lastModified);
  walkPrint("%d", song->lengthInSeconds);
  for (int i = 0; i < kNumberOfTags; ++i) walkPrint("%s", song->tags[i]);
  walkPrint("}");
}

static void walkTreeNode(int p_node, BOOL _onRootLevel) {
  struct TreeNode *node = [Tree treeNodeDataForP:p_node];
  
  if (node->p_song != -1) {
    dumpSong(node);
  } else {
    size_t pathSize = strlen(pathBuff);
    if (node->p_parent > 0) strcat(pathBuff, "/");
    strcat(pathBuff, node->name);
    
    uint64 hash = folderHash(pathBuff);
    
    if (pathsToRescan[0].count(hash)) {
      walkFolderNonRecursively(_onRootLevel);
    } else if (pathsToRescan[1].count(hash)) {
      walkFolder(pathBuff, _onRootLevel);
    } else {
      if (p_node > 0) {
        walkPrint("+ %s", _onRootLevel? pathBuff: node->name);
        walkPrint("%lld", node->inode);
      }
      
      for (auto child = node->children.begin(); child != node->children.end(); ++child) {
        walkTreeNode(*child, p_node == 0);
      }
      
      if (p_node > 0) walkPrint("-");
    }
    
    pathBuff[pathSize] = 0;
  }
}

@end
