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

+ (void)initLibrary {
  loadLibrary();
}

+ (void)rescanLibrary {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    walkLibrary();
    rescanID3s();
  });
}

+ (void)rescanFolder:(NSString *)folderPath {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    rescanFolder([folderPath cStringUsingEncoding:NSUTF8StringEncoding]);
    rescanID3s();
  });
}

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
        int node = [Tree addChild:lineBuff+2 parent:treePath.back() song:-1];
        treePath.push_back(node);
      } else if (firstChar == '-') {
        treePath.pop_back();
      } else if (firstChar == '{') {
        int song = [Tree newSong];
        struct LibrarySong *songData = [Tree songDataForP:song];
        
        fgets(lineBuff, kBuffSize, f);
        sscanf(lineBuff, "%d", &songData->inode);
        
        fgets(lineBuff, kBuffSize, f);
        sscanf(lineBuff, "%d", &songData->lastModified);
        
        fgets(lineBuff, kBuffSize, f);
        [Tree addChild:lineBuff parent:treePath.back() song:song];
        [Tree addToSongByInodeMap:song inode:songData->inode];
        
        fgets(lineBuff, kBuffSize, f);
        sscanf(lineBuff, "%d", &songData->lengthInSeconds);
        
        for (int i = 0; i < kNumberOfTags; ++i) {
          fgets(lineBuff, kBuffSize, f);
          tagsSet(songData->tags, i, lineBuff);
        }
        
        fgets(lineBuff, kBuffSize, f); // skip '}'
      } else {
        if (treePath.size() > 1) {
          treePath.pop_back();
        }
        
        NSString *folderName = stringFromBuff(lineBuff);
        fgets(lineBuff, kBuffSize, f);
        
        int node = [Tree addChild:lineBuff parent:0 song:-1];
        [Tree setLibraryPath:folderName forNode:node];
        treePath.push_back(node);
      }
    }
    
    fclose(f);
  }
}

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

static void rescanFolder(const char *folderPath) {
  @autoreleasepool {
    initWalk();
    
    FILE *f = fopen(libPath(), "r");
    vector<size_t> slashPositions;
    BOOL withinSong = NO;
    
    for (pathBuff[0] = 0; fgets(lineBuff, kBuffSize, f) != NULL;) {
      char firstChar = lineBuff[0];
      
      lineBuff[strlen(lineBuff)-1] = 0; // remove newline
      
      if (firstChar == '+') {
        strcat(pathBuff, lineBuff+2);
        size_t len = strlen(pathBuff);
        slashPositions.push_back(len);
        
        if (strcmp(folderPath, pathBuff) == 0) {
          fprintf(walkFile, "%s\n", lineBuff);
          ++lineNumber;
          
          lastFolderLevel = 0;
          wasLastItemFolder = NO;
          nftw(folderPath, ftw_callback, 512, 0);
          for (int i = 0; i < lastFolderLevel; ++i) {
            fprintf(walkFile, "-\n");
            ++lineNumber;
          }
          
          BOOL inSong = NO;
          for (int depth = 1; depth > 0;) {
            fgets(lineBuff, kBuffSize, f);
            if (lineBuff[0] == '{') inSong = YES;
            if (lineBuff[0] == '}') inSong = NO;
            if (inSong) continue;
            if (lineBuff[0] == '+') ++depth;
            if (lineBuff[0] == '-') --depth;
          }
          
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
        strcpy(pathBuff, lineBuff);
        strcat(pathBuff, "/");
        slashPositions.clear();
        slashPositions.push_back(strlen(pathBuff)-1);
        fprintf(walkFile, "%s\n", lineBuff);
        fgets(lineBuff, kBuffSize, f);
        fprintf(walkFile, "%s", lineBuff);
        lineNumber += 2;
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
