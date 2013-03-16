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

- (void)startPlayingCurrentItem;
- (void)playItemWithIndex:(int)index;

// used only by GlobalShortcuts class
- (void)playOrPause;
- (void)next;
- (void)prev;

@end
