//
//  Player.h
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Playlist;

@interface Player : NSObject

@property (nonatomic, strong) Playlist *nowPlayingPlaylist;

- (BOOL)nowPlayingItemFromPlaylist:(Playlist *)playlist;

- (void)playSelectedPlaylist;
- (void)playItemWithIndex:(int)index;

// used only by GlobalShortcuts and MediaKeyManager
- (void)playOrPause;
- (void)next;
- (void)prev;

- (void)storePlayerState;
- (void)restorePlayerState;

@property (nonatomic, assign) BOOL shuffle;
@property (nonatomic, assign) BOOL repeat;

@end
