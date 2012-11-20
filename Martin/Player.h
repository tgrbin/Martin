//
//  Player.h
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MartinAppDelegate.h"

@class PlaylistItem;

@interface Player : NSObject <NSSoundDelegate> {
  BOOL isPlaying;
  
  NSSound *nowPlayingSound;
  PlaylistItem *nowPlayingItem;
  
  NSTimer *seekTimer;
  IBOutlet NSSlider *seekSlider;
  IBOutlet MartinAppDelegate *appDelegate;
}

@property (nonatomic, assign) double volume;
@property (nonatomic, assign) double seek;

- (void)play;

@end
