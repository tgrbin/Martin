//
//  Player.h
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Playlist;

@interface Player : NSObject {
  NSTimer *seekTimer;
  IBOutlet NSSlider *seekSlider;
  IBOutlet NSButton *playOrPauseButton;
}

+ (Player *)sharedPlayer;

@property (nonatomic, strong) Playlist *nowPlayingPlaylist;

- (void)playItemWithIndex:(int)index;

@end
