//
//  PlaylistFileFormats.h
//  Martin
//
//  Created by Tomislav Grbin on 02/03/14.
//
//

#import <Foundation/Foundation.h>

@interface PlaylistFile : NSObject

+ (NSArray *)supportedFileFormats;

+ (BOOL)isFileAPlaylist:(NSString *)filename;
+ (PlaylistFile *)playlistFileWithFilename:(NSString *)filename;

- (void)loadWithBlock:(void (^)(NSArray *playlistItems))block;
- (void)saveItems:(NSArray *)items withBlock:(void (^)(BOOL success))block;

@end
