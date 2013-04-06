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

+ (NSArray *)playlistItemsFromFolder:(NSString *)folder {
  @synchronized(self) {
    struct stat statBuff;
    playlistItems = [NSMutableArray new];

    const char *cpath = [folder UTF8String];
    stat(cpath, &statBuff);

    if (statBuff.st_mode&S_IFDIR) {
      nftw(cpath, ftw_callback, 512, 0);
    } else if (statBuff.st_mode&S_IFREG) {
      checkAndAdd(cpath, statBuff.st_ino);
    }

    return playlistItems;
  }
}

static int ftw_callback(const char *filename, const struct stat *stat_struct, int flags, struct FTW *ftw_struct) {
  BOOL isFolder = (flags == FTW_D);

  if (isFolder == NO) {
    checkAndAdd(filename, stat_struct->st_ino);
  }

  return 0;
}

static void checkAndAdd(const char *filename, ino_t inode) {
  if ([FileExtensionChecker isExtensionAcceptable:filename]) {
    PlaylistItem *item = [[PlaylistItem alloc] initWithPath:@(filename) andInode:inode];
    if (item) [playlistItems addObject:item];
  }
}

@end
