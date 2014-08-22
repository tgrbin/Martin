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
#import "Playlist.h"
#import "PlaylistItem.h"
#import "FileExtensionChecker.h"
#import "MartinAppDelegate.h"
#import "Stream.h"

#import "NSString+Stream.h"

#include <sys/stat.h>

@implementation PlaylistFile

+ (NSArray *)supportedFileFormats {
  return @[ @"m3u", @"pls" ];
}

+ (PlaylistFile *)playlistFileWithFilename:(NSString *)filename {
  if (![self isFileAPlaylist:filename]) {
    return nil;
  } else {
    NSString *extension = [[filename pathExtension] lowercaseString];
    Class playlistFileClass = [extension isEqualToString:@"m3u"]? [M3UPlaylistFile class]: [PLSPlaylistFile class];
    
    PlaylistFile *playlistFile = [playlistFileClass new];
    playlistFile.filename = filename;
    return playlistFile;
  }
}

+ (BOOL)isFileAPlaylist:(NSString *)filename {
  NSString *extension = [[filename pathExtension] lowercaseString];
  return [[self supportedFileFormats] containsObject:extension];
}

- (void)loadWithBlock:(void (^)(NSArray *playlistItems))block {
  ++[MartinAppDelegate get].martinBusy;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSStringEncoding encoding;
    NSError *error;
    NSString *contents = [NSString stringWithContentsOfFile:self.filename
                                               usedEncoding:&encoding
                                                      error:&error];
    NSMutableArray *items = [NSMutableArray new];
    if (error == nil) {
      NSArray *lines = [contents componentsSeparatedByString:@"\n"];
      for (NSString *line in lines) {
        NSString *path = [self itemFullPathFromLineString:line];
        if (path != nil) {
          PlaylistItem *item = [self playlistItemFromPath:path];
          if (item) {
            [items addObject:item];
          }
        }
      }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      block(items);
      --[MartinAppDelegate get].martinBusy;
    });
  });
}

- (PlaylistItem *)playlistItemFromPath:(NSString *)path {
  NSString *extension = [[path pathExtension] lowercaseString];
  
  if ([path isURL]) {
    Stream *stream = [[MartinAppDelegate get].streamsController createOrReturnStreamWithURLString:path];
    return [stream createPlaylistItem];
  } else if ([[FileExtensionChecker acceptableExtensions] containsObject:extension]) {
    const char *cpath = [path UTF8String];
    struct stat statBuff;
    
    if (stat(cpath, &statBuff) == 0 && statBuff.st_mode&S_IFREG) { // if it's a file
      return [[PlaylistItem alloc] initWithPath:path andInode:statBuff.st_ino];
    }
  }
  
  return nil;
}

- (BOOL)savePlaylist:(Playlist *)playlist {
  NSMutableArray *paths = [NSMutableArray new];
  for (int i = 0; i < playlist.numberOfItems; ++i) {
    PlaylistItem *item = playlist[i];
    [paths addObject:item.filename];
  }
  
  NSString *string = [self stringFromPaths:paths];
  return [string writeToFile:self.filename
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:nil];
}

// to override
- (NSString *)itemFullPathFromLineString:(NSString *)lineString { return nil; }
- (NSString *)stringFromPaths:(NSArray *)paths { return nil; }

@end
