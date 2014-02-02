//
//  LastFM.h
//  Martin
//
//  Created by Tomislav Grbin on 12/17/11.
//

#import <Foundation/Foundation.h>

@class PlaylistItem;

@interface LastFM : NSObject

+ (void)getAuthURLWithBlock:(void (^)(NSString *))callbackBlock;
+ (void)getSessionKey:(void (^)(BOOL))callbackBlock;

+ (BOOL)isScrobbling;
+ (void)stopScrobbling;

+ (void)updateNowPlaying:(PlaylistItem *)playlistItem;
+ (void)scrobble:(PlaylistItem *)playlistItem;

@end
