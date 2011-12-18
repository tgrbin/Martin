//
//  Player.m
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TableSongsDataSource.h"
#import "PlaylistManager.h"
#import "LibManager.h"
#import "LastFM.h"
#import "Player.h"
#import "Song.h"

@implementation Player

@synthesize nowPlayingSound, appDelegate, nowPlayingSong;
@synthesize nextButton, playButton, prevButton;

- (void)playSong:(Song*)song {
    [nowPlayingSound stop];
    self.nowPlayingSound = [[NSSound alloc] initWithContentsOfFile:song.fullPath byReference:YES];
    nowPlayingSound.delegate = self;
    [nowPlayingSound play];
    isPlaying = YES;
    self.nowPlayingSong = song;
    
    [LastFM updateNowPlaying:song];
    
    TableSongsDataSource *tableSongsDataSource = (TableSongsDataSource*) appDelegate.songsTableView.dataSource;
    [tableSongsDataSource highlightSong:song.ID];
}

- (void) stop {
    if( nowPlayingSound ) {
        [nowPlayingSound stop];
        self.nowPlayingSound = nil;
    }
}

- (void) play {
    Song *song = [LibManager songByID:[appDelegate.playlistManager currentSongID]];
    [self playSong:song];
}

- (void) playOrPause {
    Song *song = [LibManager songByID:[appDelegate.playlistManager currentSongID]];
    
    if( nowPlayingSound == nil ) {
        [self playSong:song];
    } else {
        if( isPlaying ) [nowPlayingSound pause];
        else [nowPlayingSound resume];
        isPlaying = !isPlaying;
    }
}

- (void) next {
    Song *song = [LibManager songByID:[appDelegate.playlistManager nextSongID]];
    [self playSong:song];
}

- (void) prev {
    Song *song = [LibManager songByID:[appDelegate.playlistManager prevSongID]];
    [self playSong:song];
}

- (IBAction)buttonPressed:(id)sender {
    if( sender == nextButton ) [self next];
    else if (sender == prevButton ) [self prev];
    else [self playOrPause];
}

#pragma mark - nssound delegate

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool {
    if( aBool ) {
        [LastFM scrobble:nowPlayingSong];
        [self next];
    }
    else self.nowPlayingSound = nil;
}

@end
