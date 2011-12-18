//
//  Player.h
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MartinAppDelegate.h"

@interface Player : NSObject <NSSoundDelegate> {
    BOOL isPlaying;
}

@property (nonatomic, retain) NSSound *nowPlayingSound;
@property (nonatomic, retain) Song *nowPlayingSong;

@property (assign) IBOutlet MartinAppDelegate *appDelegate;
@property (nonatomic, retain) IBOutlet NSButton *nextButton;
@property (nonatomic, retain) IBOutlet NSButton *playButton;
@property (nonatomic, retain) IBOutlet NSButton *prevButton;

- (IBAction)buttonPressed:(id)sender;

- (void)play;
- (void)stop;
- (void)playOrPause;
- (void)next;
- (void)prev;

@end
