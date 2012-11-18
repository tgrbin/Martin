//
//  Player.m
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Carbon/Carbon.h>

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
  self.nowPlayingSound = [[NSSound alloc] initWithContentsOfFile:song.filename byReference:YES];
  nowPlayingSound.delegate = self;
  nowPlayingSound.volume = _volume;
  [nowPlayingSound play];
  isPlaying = YES;
  self.nowPlayingSong = song;
  
  [LastFM updateNowPlaying:song];
  
  TableSongsDataSource *tableSongsDataSource = (TableSongsDataSource*) appDelegate.songsTableView.dataSource;
  [tableSongsDataSource highlightSong:song.inode];
}

- (void)stop {
  if (nowPlayingSound) {
    [nowPlayingSound stop];
    self.nowPlayingSound = nil;
  }
}

- (void)play {
  Song *song = [[LibManager sharedManager] songByID:[appDelegate.playlistManager currentSongID]];
  [self playSong:song];
}

- (void)playOrPause {
  Song *song = [[LibManager sharedManager] songByID:[appDelegate.playlistManager currentSongID]];
  
  if (nowPlayingSound == nil) {
    [self playSong:song];
  } else {
    if (isPlaying) [nowPlayingSound pause];
    else [nowPlayingSound resume];
    isPlaying = !isPlaying;
  }
}

- (void)next {
  Song *song = [[LibManager sharedManager] songByID:[appDelegate.playlistManager nextSongID]];
  [self playSong:song];
}

- (void)prev {
  Song *song = [[LibManager sharedManager] songByID:[appDelegate.playlistManager prevSongID]];
  [self playSong:song];
}

- (IBAction)buttonPressed:(id)sender {
  if (sender == nextButton) [self next];
  else if (sender == prevButton) [self prev];
  else [self playOrPause];
}

- (void)setVolume:(double)volume {
  _volume = volume;
  if (nowPlayingSound) nowPlayingSound.volume = _volume;
}

#pragma mark - nssound delegate

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool {
  if (aBool) {
    [LastFM scrobble:nowPlayingSong];
    [self next];
  }
  else self.nowPlayingSound = nil;
}

#pragma mark - hot keys

OSStatus hotkeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData);

OSStatus hotkeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
  EventHotKeyID hkCom;
  GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hkCom), NULL, &hkCom);

  Player *player = (__bridge Player *)userData;
  int _id = hkCom.id;
  
  if (_id == 1 ) [player playOrPause];
  else if (_id == 2) [player prev];
  else if (_id == 3) [player next];

  return noErr;
}

- (void) awakeFromNib {
  self.volume = 0.5;
  
  EventHotKeyRef hkRef;
  EventHotKeyID hkID;
  EventTypeSpec eventType;
  eventType.eventClass=kEventClassKeyboard;
  eventType.eventKind=kEventHotKeyPressed;

  InstallApplicationEventHandler(&hotkeyHandler, 1, &eventType, (__bridge void *)self, NULL);
  
  hkID.signature = 'play';
  hkID.id = 1;
  RegisterEventHotKey(7, shiftKey+cmdKey, hkID, GetApplicationEventTarget(), 0, &hkRef);
  
  hkID.signature = 'prev';
  hkID.id = 2;
  RegisterEventHotKey(13, shiftKey+cmdKey, hkID, GetApplicationEventTarget(), 0, &hkRef);
  
  hkID.signature = 'next';
  hkID.id = 3;
  RegisterEventHotKey(14, shiftKey+cmdKey, hkID, GetApplicationEventTarget(), 0, &hkRef);
}

@end
