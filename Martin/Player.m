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
#import "LastFM.h"
#import "Player.h"
#import "PlaylistItem.h"

@implementation Player

- (void)awakeFromNib {
  self.volume = 0.5;
  [self setupHotkeyEvents];
  seekSlider.enabled = NO;
}

- (void)playItem:(PlaylistItem *)item {
  [nowPlayingSound stop];
  
  if (item == nil) return;
  
  nowPlayingSound = [[NSSound alloc] initWithContentsOfFile:item.filename byReference:YES];
  nowPlayingSound.delegate = self;
  nowPlayingSound.volume = _volume;
  [nowPlayingSound play];
  
  seekSlider.enabled = YES;
  [self startSeekTimer];
  
  isPlaying = YES;
  nowPlayingItem = item;
  
  [LastFM updateNowPlaying:item];
  
  [((TableSongsDataSource*) appDelegate.songsTableView.dataSource) playingItemChanged];
}

- (void)stop {
  if (nowPlayingSound) {
    [nowPlayingSound stop];
    nowPlayingSound = nil;
    self.seek = 0;
    [seekTimer invalidate];
    seekTimer = nil;
    seekSlider.enabled = NO;
  }
}

- (void)play {
  [self playItem:appDelegate.playlistManager.currentItem];
}

- (void)playOrPause {
  if (nowPlayingSound == nil) {
    [self playItem:appDelegate.playlistManager.currentItem];
  } else {
    if (isPlaying) [nowPlayingSound pause];
    else [nowPlayingSound resume];
    isPlaying = !isPlaying;
  }
}

- (void)next {
  [self playItem:appDelegate.playlistManager.nextItem];
}

- (void)prev {
  [self playItem:appDelegate.playlistManager.prevItem];
}

- (void)setVolume:(double)volume {
  _volume = volume;
  if (nowPlayingSound) nowPlayingSound.volume = _volume;
}

- (void)startSeekTimer {
  if (seekTimer != nil) {
    [seekTimer invalidate];
    seekTimer = nil;
  }
  seekTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                               target:self
                                             selector:@selector(updateSeekTime)
                                             userInfo:nil
                                              repeats:YES];
}

- (void)updateSeekTime {
  if (nowPlayingSound == nil) {
    self.seek = 0;
    [seekTimer invalidate];
    seekTimer = nil;
    seekSlider.enabled = NO;
  } else {
    self.seek = nowPlayingSound.currentTime / nowPlayingSound.duration;
  }
}

#pragma mark - actions

- (IBAction)seekSliderChanged:(NSSlider *)sender {
  if (nowPlayingSound) {
    nowPlayingSound.currentTime = sender.doubleValue * nowPlayingSound.duration;
  }
}

- (IBAction)prevPressed:(id)sender {
  [self prev];
}

- (IBAction)playOrPausePressed:(id)sender {
  [self playOrPause];
}

- (IBAction)nextPressed:(id)sender {
  [self next];
}

#pragma mark - nssound delegate

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool {
  if (aBool) {
    [LastFM scrobble:nowPlayingItem];
    [self next];
  } else {
    nowPlayingSound = nil;
  }
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
