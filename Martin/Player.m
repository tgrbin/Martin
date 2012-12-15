//
//  Player.m
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "Player.h"
#import "PlaylistTableManager.h"
#import "PlaylistManager.h"
#import "LastFM.h"
#import "PlaylistItem.h"
#import "FilePlayer.h"
#import "Playlist.h"
#import "LibManager.h"

@implementation Player

static Player *sharedPlayer = nil;

+ (Player *)sharedPlayer {
  return sharedPlayer;
}

- (void)awakeFromNib {
  sharedPlayer = self;
  [self setupHotkeyEvents];
  seekSlider.enabled = NO;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(trackFinished)
                                               name:kFilePlayerPlayedItemNotification
                                             object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startPlayingCurrentItem {
  if (_nowPlayingPlaylist.numberOfItems == 0) return;
  if (_nowPlayingPlaylist.currentItem == nil) [_nowPlayingPlaylist moveToFirstItem];

  [[FilePlayer sharedPlayer] startPlayingItem:_nowPlayingPlaylist.currentItem];
  [self startSeekTimer];
  [self setPlayOrPause:YES];
  [LastFM updateNowPlaying:_nowPlayingPlaylist.currentItem];
}

- (void)trackFinished {
  [LastFM scrobble:_nowPlayingPlaylist.currentItem];
  [self next];
}

- (void)stop {
  [self setPlayOrPause:YES];
  [self disableTimer];
  [[FilePlayer sharedPlayer] stop];
}

- (void)playOrPause {
  if ([[FilePlayer sharedPlayer] stopped]) {
    [self startPlayingCurrentItem];
  } else {
    [[FilePlayer sharedPlayer] togglePause];
    [self setPlayOrPause:[[FilePlayer sharedPlayer] playing]];
  }
}

- (void)next {
  if ([_nowPlayingPlaylist moveToNextItem] == nil) {
    [self stop];
  } else {
    [self startPlayingCurrentItem];
  }
}

- (void)prev {
  if ([_nowPlayingPlaylist moveToPrevItem] == nil) {
    [self stop];
  } else {
    [self startPlayingCurrentItem];
  }
}

- (void)startSeekTimer {
  if (seekTimer != nil) {
    [self disableTimer];
  }
  seekSlider.enabled = YES;
  seekTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                               target:self
                                             selector:@selector(updateSeekTime)
                                             userInfo:nil
                                              repeats:YES];
}

- (void)updateSeekTime {
  if ([[FilePlayer sharedPlayer] stopped]) {
    [self disableTimer];
  } else {
    seekSlider.doubleValue = [[FilePlayer sharedPlayer] seek];
  }
}

- (void)disableTimer {
  [seekTimer invalidate];
  seekTimer = nil;
  seekSlider.enabled = NO;
  seekSlider.doubleValue = 0;
}

- (void)setPlayOrPause:(BOOL)play {
  playOrPauseButton.title = play? @">": @"II";
}

#pragma mark - actions

- (IBAction)seekSliderChanged:(NSSlider *)sender {
  [[FilePlayer sharedPlayer] setSeek:sender.doubleValue];
}

- (IBAction)prevPressed:(id)sender {
  [[LibManager sharedManager] rescanFolder:"/Users/tomislav/Music/Klasika/Chopin" withBlock:^(int p) {

  }];

//  if ([[FilePlayer sharedPlayer] stopped]) return;
//  [self setNowPlayingPlaylistIfNecessary];
//  [self prev];
}

- (IBAction)playOrPausePressed:(id)sender {
  [self setNowPlayingPlaylistIfNecessary];
  [self playOrPause];
}

- (IBAction)nextPressed:(id)sender {
  if ([[FilePlayer sharedPlayer] stopped]) return;
  [self setNowPlayingPlaylistIfNecessary];
  [self next];
}

- (IBAction)stopPressed:(id)sender {
  [self stop];
  _nowPlayingPlaylist = nil;
}

- (void)setNowPlayingPlaylistIfNecessary {
  if (_nowPlayingPlaylist == nil) _nowPlayingPlaylist = [PlaylistManager sharedManager].selectedPlaylist;
}

- (void)playItemWithIndex:(int)index {
  _nowPlayingPlaylist = [[PlaylistManager sharedManager] selectedPlaylist];
  [_nowPlayingPlaylist moveToItemWithIndex:index];
  [self startPlayingCurrentItem];
}

#pragma mark - hot keys

static OSStatus hotkeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
  EventHotKeyID hkCom;
  GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hkCom), NULL, &hkCom);

  Player *player = (__bridge Player *)userData;
  int _id = hkCom.id;

  if (_id == 1 ) [player playOrPause];
  else if (_id == 2) [player prev];
  else if (_id == 3) [player next];

  return noErr;
}

- (void)setupHotkeyEvents {
  EventHotKeyRef hkRef;
  EventHotKeyID hkID;
  EventTypeSpec eventType;
  eventType.eventClass = kEventClassKeyboard;
  eventType.eventKind = kEventHotKeyPressed;

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
