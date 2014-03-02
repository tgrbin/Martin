//
//  PlaylistFileFormats.m
//  Martin
//
//  Created by Tomislav Grbin on 02/03/14.
//
//

#import "PlaylistFile.h"
#import "PlaylistFile+private.h"
#import "M3UPlaylistFile.h"
#import "PLSPlaylistFile.h"
#import "PlaylistItem.h"
#import "FileExtensionChecker.h"

#include <sys/stat.h>

@implementation PlaylistFile

+ (NSArray *)supportedFileFormats {
  return @[ @"m3u", @"pls" ];
}

+ (PlaylistFile *)playlistFileWithFilename:(NSString *)filename {
  NSString *extension = [[filename pathExtension] lowercaseString];
  Class playlistFileClass = [extension isEqualToString:@"m3u"]? [M3UPlaylistFile class]: [PLSPlaylistFile class];
  
  PlaylistFile *playlistFile = [playlistFileClass new];
  playlistFile.filename = filename;
  return playlistFile;
}

- (void)loadWithBlock:(void (^)(NSArray *playlistItems))block {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSStringEncoding encoding;
    NSError *error;
    NSString *contents = [NSString stringWithContentsOfFile:self.filename
                                               usedEncoding:&encoding
                                                      error:&error];
    if (error != nil) {
      block(nil);
    } else {
      NSArray *lines = [contents componentsSeparatedByString:@"\n"];
      NSMutableArray *items = [NSMutableArray new];
      for (NSString *line in lines) {
        NSString *path = [self itemFullPathFromLineString:line];
        if (path != nil) {
          PlaylistItem *item = [self playlistItemFromPath:path];
          if (item) [items addObject:item];
        }
      }
    }
  });
}

- (PlaylistItem *)playlistItemFromPath:(NSString *)path {
  NSString *extension = [[path pathExtension] lowercaseString];
  
  if ([[FileExtensionChecker acceptableExtensions] containsObject:extension]) {
    const char *cpath = [path UTF8String];
    struct stat statBuff;
    stat(cpath, &statBuff);
    
    if (statBuff.st_mode&S_IFREG) { // if it's a file
      return [[PlaylistItem alloc] initWithPath:path andInode:statBuff.st_ino];
    }
  }
  
  return nil;
}

- (void)saveItems:(NSArray *)playlistItems withBlock:(void (^)(BOOL success))block {

}

- (NSString *)itemFullPathFromLineString:(NSString *)lineString { return nil; }

@end
