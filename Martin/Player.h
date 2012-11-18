//
//  Player.h
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MartinAppDelegate.h"

@class Song;

@interface Player : NSObject <NSSoundDelegate> {
  BOOL isPlaying;
  
  NSTimer *seekTimer;
  IBOutlet NSSlider *seekSlider;
}

@property (nonatomic, strong) NSSound *nowPlayingSound;
@property (nonatomic, strong) Song *nowPlayingSong;

@property (nonatomic, assign) double volume;
@property (nonatomic, assign) double seek;

@property (weak) IBOutlet MartinAppDelegate *appDelegate;
@property (nonatomic, strong) IBOutlet NSButton *nextButton;
@property (nonatomic, strong) IBOutlet NSButton *playButton;
@property (nonatomic, strong) IBOutlet NSButton *prevButton;

- (IBAction)buttonPressed:(id)sender;

- (void)play;
- (void)stop;
- (void)playOrPause;
- (void)next;
- (void)prev;

@end
