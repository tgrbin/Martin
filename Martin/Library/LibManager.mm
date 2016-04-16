//
//  LibManager.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//

#import "LibManager.h"
#import "LibraryFoldersController.h"
#import "ID3Reader.h"
#import "LibraryTree.h"
#import "LibrarySong.h"
#import "Tags.h"
#import "LibraryTreeNode.h"
#import "FolderWatcher.h"
#import "RescanState.h"
#import "ResourcePath.h"
#import "FileExtensionChecker.h"

#import <algorithm>
#import <cstdio>
#import <vector>
#import <ftw.h>
#import <dirent.h>
#import <unordered_set>

using namespace std;

@implementation LibManager

static const int kBuffSize = 1<<16;
static char lineBuff[kBuffSize];
static char pathBuff[kBuffSize];

static vector<int> needsRescan;

static int lastFolderLevel;
static BOOL folderIsEmpty;
static BOOL wasLastItemFolder;
static BOOL onRootLevel;
static int lineNumber;
static FILE *walkFile;

static unordered_set<uint64> pathsToRescan[2];

+ (void)initLibrary {
  static BOOL libraryLoaded = NO;
  
  if (libraryLoaded == NO) {
    loadLibrary();
    libraryLoaded = YES;
  }
}

+ (void)rescanAll {
  static struct stat statBuff;
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    initWalk();
    
    BOOL watchingFolders = [FolderWatcher sharedWatcher].enabled;
    for (NSString *s in [LibraryFoldersController libraryFolders]) {
      const char *folder = [s UTF8String];
      
      if (watchingFolders) {
        if (stat(folder, &statBuff) == 0) {
          int node = [LibraryTree nodeByInode:statBuff.st_ino];
          if (node == -1) walkFolder(folder, YES);
          else {
            if ([LibraryTree treeNodeDataForP:node]->p_parent > 0) {
              strcpy(pathBuff, folder);
              *strrchr(pathBuff, '/') = 0;
            }
            walkTreeNode(node, YES);
          }
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

static void initWalk() {
  [RescanState sharedState].state = kRescanStateTraversing;
  walkFile = fopen([ResourcePath rescanPath], "w");
  lineNumber = 0;
  needsRescan.clear();
  pathBuff[0] = 0;
}

static void endWalk() {
  fclose(walkFile);
  pathsToRescan[0].clear();
  pathsToRescan[1].clear();
  pathBuff[0] = 0;
}

#pragma mark - load library

static int readTreeNode(FILE *f, int parent) {
  int node = [LibraryTree addChild:lineBuff+2 parent:parent];
  fscanf(f, "%lld\n", &[LibraryTree treeNodeDataForP:node]->inode);
  [LibraryTree addToNodeByInodeMap:node];
  return node;
}

static void loadLibrary() {
  [LibraryTree clearTree];
  
  FILE *f = fopen([ResourcePath libPath], "r");
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
      int song = [LibraryTree newSong];
      struct LibrarySong *songData = [LibraryTree songDataForP:song];
      
      songData->p_treeLeaf = node;
      [LibraryTree treeNodeDataForP:node]->p_song = song;
      
      fscanf(f, "%ld", &songData->lastModified);
      fscanf(f, "%d", &songData->lengthInSeconds);
      fgets(lineBuff, kBuffSize, f); // read just the newline
      for (int i = 0; i < kNumberOfTags; ++i) {
        fgets(lineBuff, kBuffSize, f);
        lineBuff[strlen(lineBuff) - 1] = 0; // remove the newline
        songData->tags[i] = @(lineBuff);
      }
    }
  }
  
  fclose(f);
}

#pragma mark - rescan songs

static BOOL rescanSong(FILE *f) {
  ID3Reader *id3 = [[ID3Reader alloc] initWithFile:@(pathBuff)];
  BOOL success = (id3 != nil);
  
  if (success) {
    fprintf(f, "%d\n", id3.lengthInSeconds);
    for (int i = 0; i < kNumberOfTags; ++i) {
      NSString *val = [id3 tag:[Tags tagNameForIndex:(TagIndex)i]];
      fprintf(f, "%s\n", val? [val UTF8String]: "");
    }
    [id3 release];
  } else {
    fprintf(f, "0\n");
    for (int i = 0; i < kNumberOfTags; ++i) fprintf(f, "\n");
  }
  
  ++[RescanState sharedState].alreadyRescannedSongs;
  return success;
}

static void rescanID3s() {
  @autoreleasepool {
    if ([RescanState sharedState].songsToRescan > 0) {
      rename([ResourcePath libPath], [ResourcePath rescanHelperPath]);
      rename([ResourcePath rescanPath], [ResourcePath libPath]);
      [RescanState sharedState].state = kRescanStateReloadingLibrary;
      loadLibrary();
      [RescanState sharedState].state = kRescanStateReadingID3s;
      rename([ResourcePath libPath], [ResourcePath rescanPath]);
      rename([ResourcePath rescanHelperPath], [ResourcePath libPath]);
    }
    
    FILE *f = fopen([ResourcePath rescanPath], "r");
    FILE *g = fopen([ResourcePath rescanHelperPath], "w");
    
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
    
    unlink([ResourcePath libPath]);
    rename([ResourcePath rescanHelperPath], [ResourcePath libPath]);

    unlink([ResourcePath rescanHelperPath]);
    unlink([ResourcePath rescanPath]);
    
    [RescanState sharedState].state = kRescanStateReloadingLibrary;
    loadLibrary();
    [RescanState sharedState].state = kRescanStateIdle;
  }
}

#pragma mark - walking

static void walkSong(const char *name, int p_song, const struct stat *statBuff) {
  time_t lastModified = statBuff->st_mtimespec.tv_sec;
  
  walkPrint("{ %s", name);
  walkPrint("%lld", statBuff->st_ino);
  walkPrint("%ld", lastModified);
  
  struct LibrarySong *song = (p_song == -1)? NULL: [LibraryTree songDataForP:p_song];
  
  if (p_song == -1 || song->lastModified != lastModified) {
    needsRescan.push_back(lineNumber - 3);
    ++[RescanState sharedState].songsToRescan;
    walkPrint("0");
    for (int i = 0; i < kNumberOfTags; ++i) walkPrint("");
  } else {
    walkPrint("%d", song->lengthInSeconds);
    for (int i = 0; i < kNumberOfTags; ++i) walkPrint("%s", song->tags[i]);
  }
  
  walkPrint("}");
  
  ++[RescanState sharedState].numberOfSongsFound;
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
    if (currentLevel > 0) folderIsEmpty = NO;
  } else {
    if ([FileExtensionChecker isExtensionAcceptableForCStringFilename:filename]) {
      walkSong(basename, [LibraryTree songByInode:inode], stat_struct);
    }
    folderIsEmpty = NO;
  }
  
  lastFolderLevel = currentLevel;
  wasLastItemFolder = isFolder;
  
  return 0;
}

static void walkFolder(const char *folder, BOOL _onRootLevel) {
  lastFolderLevel = 0;
  wasLastItemFolder = NO;
  onRootLevel = _onRootLevel;
  folderIsEmpty = YES;
  
  nftw(folder, ftw_callback, 512, 0);
  
  for (int i = 0; i < lastFolderLevel + folderIsEmpty; ++i) walkPrint("-");
}

static void walkTreeNode(int, BOOL);

static void walkFolderNonRecursively(BOOL _onRootLevel) {
  static struct stat statBuff;
  
  DIR *dir = opendir(pathBuff);
  size_t pathLen = strlen(pathBuff);
  
  if (dir) {
    for (struct dirent *entry; (entry = readdir(dir)) != NULL;) {
      if (entry->d_name[0] == '.') {
        if (entry->d_name[1] == 0) {
          walkPrint("+ %s", _onRootLevel? pathBuff: strrchr(pathBuff, '/') + 1);
          walkPrint("%lld", entry->d_ino);
        }
        continue;
      }
      
      int node = [LibraryTree nodeByInode:entry->d_ino];
      strcat(pathBuff, "/");
      strcat(pathBuff, entry->d_name);
      
      if (entry->d_type == DT_DIR) {
        if (node == -1) {
          walkFolder(pathBuff, NO);
        } else {
          [LibraryTree setName:entry->d_name forNode:node];
          pathBuff[pathLen] = 0;
          walkTreeNode(node, NO);
        }
      } else if (entry->d_type == DT_REG && [FileExtensionChecker isExtensionAcceptableForCStringFilename:entry->d_name]) {
        if (stat(pathBuff, &statBuff) == 0) {
          int p_song = (node == -1)? -1: [LibraryTree treeNodeDataForP:node]->p_song;
          walkSong(entry->d_name, p_song, &statBuff);
        }
      }
      
      pathBuff[pathLen] = 0;
    }
    
    closedir(dir);
    walkPrint("-");
  }
}

static void dumpSong(struct LibraryTreeNode *node) {
  struct LibrarySong *song = [LibraryTree songDataForP:node->p_song];
  
  walkPrint("{ %s", node->name);
  walkPrint("%lld", node->inode);
  walkPrint("%ld", song->lastModified);
  walkPrint("%d", song->lengthInSeconds);
  for (int i = 0; i < kNumberOfTags; ++i) walkPrint("%s", song->tags[i]);
  walkPrint("}");
  
  ++[RescanState sharedState].numberOfSongsFound;
}

static void walkTreeNode(int p_node, BOOL _onRootLevel) {
  struct LibraryTreeNode *node = [LibraryTree treeNodeDataForP:p_node];
  
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
