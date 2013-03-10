//
//  SongsFinder.m
//  Martin
//
//  Created by Tomislav Grbin on 2/3/13.
//
//

#import "SongsFinder.h"
#import "FileExtensionChecker.h"
#import "Tree.h"
#import "PlaylistItem.h"

#import <ftw.h>

@implementation SongsFinder

static NSMutableArray *playlistItems;

+ (NSArray *)playlistItemsFromFolders:(NSArray *)folders {
  static struct stat statBuff;
  playlistItems = [NSMutableArray new];

  for (NSString *path in folders) {
    stat([path UTF8String], &statBuff);

    if (statBuff.st_mode&S_IFDIR) {
      nftw([path UTF8String], ftw_callback, 512, 0);
    } else if (statBuff.st_mode&S_IFREG) {
      PlaylistItem *item = [[PlaylistItem alloc] initWithPath:path andInode:statBuff.st_ino];
      if (item) [playlistItems addObject:item];
    }
  }

  return playlistItems;
}

static int ftw_callback(const char *filename, const struct stat *stat_struct, int flags, struct FTW *ftw_struct) {
  BOOL isFolder = (flags == FTW_D);

  if (isFolder == NO) {
    if ([FileExtensionChecker isExtensionAcceptable:filename]) {
      PlaylistItem *item = [[PlaylistItem alloc] initWithPath:@(filename) andInode:stat_struct->st_ino];
      if (item) [playlistItems addObject:item];
    }
  }

  return 0;
}

@end
