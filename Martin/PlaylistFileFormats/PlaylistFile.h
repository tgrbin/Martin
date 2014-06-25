//
//  PlaylistFileFormats.h
//  Martin
//
//  Created by Tomislav Grbin on 02/03/14.
//
//

#import <Foundation/Foundation.h>

@class Playlist;

@interface PlaylistFile : NSObject

+ (PlaylistFile *)playlistFileWithFilename:(NSString *)filename;

+ (NSArray *)supportedFileFormats;
+ (BOOL)isFileAPlaylist:(NSString *)filename;

- (void)loadWithBlock:(void (^)(NSArray *playlistItems))block;

- (BOOL)savePlaylist:(Playlist *)playlist;

@end
