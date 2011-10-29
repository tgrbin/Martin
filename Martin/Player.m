//
//  Player.m
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaylistManager.h"
#import "LibManager.h"
#import "Player.h"
#import "Song.h"

@implementation Player

@synthesize nowPlayingSound, appDelegate;
@synthesize nextButton, playButton, prevButton;

- (void)playFile:(NSString*)fileName {
    [nowPlayingSound stop];
    self.nowPlayingSound = [[NSSound alloc] initWithContentsOfFile:fileName byReference:YES];
    [nowPlayingSound play];
    isPlaying = YES;
}

- (void) play {
    Song *song = [LibManager songByID:[appDelegate.playlistManager currentSongID]];
    [self playFile:song.fullPath];
}

- (void) playOrPause {
    Song *song = [LibManager songByID:[appDelegate.playlistManager currentSongID]];
    
    if( nowPlayingSound == nil ) {
        [self playFile:song.fullPath];
    } else {
        if( isPlaying ) [nowPlayingSound pause];
        else [nowPlayingSound resume];
        isPlaying = !isPlaying;
    }
}

- (void) next {
    Song *song = [LibManager songByID:[appDelegate.playlistManager nextSongID]];
    [self playFile:song.fullPath];
}

- (void) prev {
    Song *song = [LibManager songByID:[appDelegate.playlistManager prevSongID]];
    [self playFile:song.fullPath];
}

- (IBAction)buttonPressed:(id)sender {
    if( sender == nextButton ) [self next];
    else if (sender == prevButton ) [self prev];
    else [self playOrPause];
}

@end
