//
//  LastFM.h
//  Martin
//
//  Created by Tomislav Grbin on 12/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PlaylistItem;

@interface LastFM : NSObject

+ (void)getAuthURLWithBlock:(void (^)(NSString *))callbackBlock;
+ (void)getSessionKey:(void (^)(BOOL))callbackBlock;
+ (void)resetSessionKey;

+ (void)updateNowPlaying:(PlaylistItem *)playlistItem;
+ (void)scrobble:(PlaylistItem *)playlistItem;

@end
