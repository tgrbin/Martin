//
//  Player.m
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MartinAppDelegate.h"
#import "Player.h"
#import "LastFM.h"
#import "Playlist.h"
#import "PlaylistItem.h"
#import "NSObject+Observe.h"

typedef enum {
  kPlayButtonStylePlay,
  kPlayButtonStylePause
} PlayButtonStyle;

@implementation Player {
  NSTimer *seekTimer;
  IBOutlet NSSlider *seekSlider;
  IBOutlet NSButton *playOrPauseButton;
  IBOutlet NSTextField *nowPlayingTextField;

  BOOL playingQueuedItem;
}

- (void)awakeFromNib {
  seekSlider.enabled = NO;
  [self observe:kFilePlayerPlayedItemNotification withAction:@selector(trackFinished)];
}

- (void)startPlayingCurrentItem {
  if (_nowPlayingPlaylist.numberOfItems == 0) return;
  if (_nowPlayingPlaylist.currentItem == nil) [_nowPlayingPlaylist moveToFirstItem];

  if (playingQueuedItem) {
    Playlist *p = [(QueuePlaylist *)_nowPlayingPlaylist currentItemPlaylist];
    if (p) [p findAndSetCurrentItemTo:_nowPlayingPlaylist.currentItem];
  }

  [[MartinAppDelegate get].filePlayer startPlayingItem:_nowPlayingPlaylist.currentItem];
  [self startSeekTimer];
  [self setPlayButtonStyle:kPlayButtonStylePause];
  [LastFM updateNowPlaying:_nowPlayingPlaylist.currentItem];

  nowPlayingTextField.stringValue = _nowPlayingPlaylist.currentItem.prettyName;
}

- (void)trackFinished {
  [LastFM scrobble:_nowPlayingPlaylist.currentItem];
  [self next];
}

- (void)stop {
  [self setPlayButtonStyle:kPlayButtonStylePlay];
  [self disableTimer];
  [[MartinAppDelegate get].filePlayer stop];
  nowPlayingTextField.stringValue = @"";
  _nowPlayingPlaylist = nil;
}

- (void)playOrPause {
  if ([[MartinAppDelegate get].filePlayer stopped]) {
    if ([self willPlayQueuedItem] == NO) {
      [self startPlayingCurrentItem];
    }
  } else {
    [[MartinAppDelegate get].filePlayer togglePause];
    [self setPlayButtonStyle:[[MartinAppDelegate get].filePlayer playing]? kPlayButtonStylePause: kPlayButtonStylePlay];
  }
}

- (void)next {
  if ([self willPlayQueuedItem] == NO) {
    if ([_nowPlayingPlaylist moveToNextItem] == nil) {
      [self stop];
    } else {
      [self startPlayingCurrentItem];
    }
  }
}

- (void)prev {
  FilePlayer *filePlayer = [MartinAppDelegate get].filePlayer;
  if (filePlayer.stopped == NO && filePlayer.timeElapsed > 3) {
    [self startPlayingCurrentItem];
    return;
  }

  if (playingQueuedItem) {
    _nowPlayingPlaylist = [[MartinAppDelegate get].playlistManager.queue currentItemPlaylist];
    playingQueuedItem = NO;
    if (_nowPlayingPlaylist == nil) {
      [self stop];
    } else {
      [self startPlayingCurrentItem];
    }
  } else {
    if ([_nowPlayingPlaylist moveToPrevItem] == nil) {
      [self stop];
    } else {
      [self startPlayingCurrentItem];
    }
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

- (void)setPlayButtonStyle:(PlayButtonStyle)style {
  playOrPauseButton.title = (style == kPlayButtonStylePlay)? @">": @"II";
}

#pragma mark - queue management

- (BOOL)willPlayQueuedItem {
  QueuePlaylist *queue = [MartinAppDelegate get].playlistManager.queue;

  if (playingQueuedItem) {
    _nowPlayingPlaylist = [queue currentItemPlaylist];
    playingQueuedItem = NO;
    [queue removeFirstItem];
    [[MartinAppDelegate get].playlistTableManager queueChanged];
    [[MartinAppDelegate get].playlistManager reload];
  }

  if ([queue isEmpty]) {
    return NO;
  } else {
    _nowPlayingPlaylist = queue;
    playingQueuedItem = YES;
    [queue moveToFirstItem];
    [self startPlayingCurrentItem];
    return YES;
  }
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

  if (_nowPlayingPlaylist == [MartinAppDelegate get].playlistManager.queue) {
    playingQueuedItem = YES;
    [_nowPlayingPlaylist reorderItemsAtRows:@[@(index)] toPos:0];
    [_nowPlayingPlaylist moveToFirstItem];
    [[MartinAppDelegate get].playlistTableManager selectFirstItem];
  } else {
    playingQueuedItem = NO;
    [_nowPlayingPlaylist moveToItemWithIndex:index];
  }

  [self startPlayingCurrentItem];
}

@end
