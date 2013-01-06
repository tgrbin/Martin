//
//  Player.m
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "MartinAppDelegate.h"
#import "Player.h"
#import "LastFM.h"
#import "Playlist.h"
#import "PlaylistItem.h"
#import "NSObject+Observe.h"

@implementation Player {
  NSTimer *seekTimer;
  IBOutlet NSSlider *seekSlider;
  IBOutlet NSButton *playOrPauseButton;
  IBOutlet NSTextField *nowPlayingTextField;
}

- (void)awakeFromNib {
  [self setupHotkeyEvents];
  seekSlider.enabled = NO;
  [self observe:kFilePlayerPlayedItemNotification withAction:@selector(trackFinished)];
}

- (void)startPlayingCurrentItem {
  if (_nowPlayingPlaylist.numberOfItems == 0) return;
  if (_nowPlayingPlaylist.currentItem == nil) [_nowPlayingPlaylist moveToFirstItem];

  [[MartinAppDelegate get].filePlayer startPlayingItem:_nowPlayingPlaylist.currentItem];
  [self startSeekTimer];
  [self setPlayOrPause:YES];
  [LastFM updateNowPlaying:_nowPlayingPlaylist.currentItem];

  nowPlayingTextField.stringValue = _nowPlayingPlaylist.currentItem.prettyName;
}

- (void)trackFinished {
  [LastFM scrobble:_nowPlayingPlaylist.currentItem];
  [self next];
}

- (void)stop {
  [self setPlayOrPause:YES];
  [self disableTimer];
  [[MartinAppDelegate get].filePlayer stop];
  nowPlayingTextField.stringValue = @"";
  _nowPlayingPlaylist = nil;
}

- (void)playOrPause {
  if ([[MartinAppDelegate get].filePlayer stopped]) {
    [self startPlayingCurrentItem];
  } else {
    [[MartinAppDelegate get].filePlayer togglePause];
    [self setPlayOrPause:[[MartinAppDelegate get].filePlayer playing]];
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
  if ([[MartinAppDelegate get].filePlayer stopped]) {
    [self disableTimer];
  } else {
    seekSlider.doubleValue = [[MartinAppDelegate get].filePlayer seek];
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
  [[MartinAppDelegate get].filePlayer setSeek:sender.doubleValue];
}

- (IBAction)prevPressed:(id)sender {
  if ([[MartinAppDelegate get].filePlayer stopped]) return;
  [self setNowPlayingPlaylistIfNecessary];
  [self prev];
}

- (IBAction)playOrPausePressed:(id)sender {
  [self setNowPlayingPlaylistIfNecessary];
  [self playOrPause];
}

- (IBAction)nextPressed:(id)sender {
  if ([[MartinAppDelegate get].filePlayer stopped]) return;
  [self setNowPlayingPlaylistIfNecessary];
  [self next];
}

- (IBAction)stopPressed:(id)sender {
  [self stop];
}

- (void)setNowPlayingPlaylistIfNecessary {
  if (_nowPlayingPlaylist == nil) _nowPlayingPlaylist = [MartinAppDelegate get].playlistManager.selectedPlaylist;
}

- (void)playItemWithIndex:(int)index {
  _nowPlayingPlaylist = [[MartinAppDelegate get].playlistManager selectedPlaylist];
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
