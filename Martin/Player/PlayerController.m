//
//  PlayerController.m
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//

#import "MartinAppDelegate.h"
#import "PlayerController.h"
#import "LastFM.h"
#import "Playlist.h"
#import "QueuePlaylist.h"
#import "PlaylistItem.h"
#import "NSObject+Observe.h"
#import "PlayerStatusTextField.h"
#import "DefaultsManager.h"

typedef enum {
  kPlayButtonStylePlay,
  kPlayButtonStylePause
} PlayButtonStyle;

@implementation PlayerController {
  NSTimer *seekTimer;
  IBOutlet NSSlider *seekSlider;
  IBOutlet NSButton *playOrPauseButton;
  IBOutlet NSButton *repeatButton;
  IBOutlet NSButton *shuffleButton;
  IBOutlet PlayerStatusTextField *playerStatusTextField;

  BOOL playingQueuedItem;
}

- (void)awakeFromNib {
  seekSlider.enabled = NO;
  [self observe:kFilePlayerPlayedItemNotification withAction:@selector(trackFinished)];
  
  self.shuffle = [[DefaultsManager objectForKey:kDefaultsKeyShuffle] boolValue];
  self.repeat = [[DefaultsManager objectForKey:kDefaultsKeyRepeat] boolValue];
}

- (BOOL)nowPlayingItemFromPlaylist:(Playlist *)playlist {
  if ([MartinAppDelegate get].filePlayer.stopped == NO) {
    if (_nowPlayingPlaylist == playlist) return YES;

    QueuePlaylist *queue = [MartinAppDelegate get].tabsManager.queue;
    if (_nowPlayingPlaylist == queue && [queue currentItemPlaylist] == playlist) {
      for (int i = 0; i < playlist.numberOfItems; ++i) {
        if (playlist[i] == queue.currentItem) return YES;
      }
    }
  }
  return NO;
}

- (void)playSelectedPlaylist {
  self.nowPlayingPlaylist = nil;
  [self setNowPlayingPlaylistIfNecessary];
  [self startPlayingCurrentItem];
}

- (void)startPlayingCurrentItem {
  if (_nowPlayingPlaylist.numberOfItems == 0) return;
  if (_nowPlayingPlaylist.currentItem == nil) [_nowPlayingPlaylist moveToNextItem];

  if (playingQueuedItem) {
    Playlist *p = [(QueuePlaylist *)_nowPlayingPlaylist currentItemPlaylist];
    if (p) {
      [p findAndSetCurrentItemTo:_nowPlayingPlaylist.currentItem];
      [p addCurrentItemToAlreadyPlayedItems];
    }
  }

  PlaylistItem *currentItem = _nowPlayingPlaylist.currentItem;
  
  [_nowPlayingPlaylist addCurrentItemToAlreadyPlayedItems];
  
  [[MartinAppDelegate get].filePlayer startPlayingItem:currentItem];
  
  [self startSeekTimerIfNecessaryWithItem:currentItem];
  
  [self setPlayButtonStyle:kPlayButtonStylePause];
  [LastFM updateNowPlaying:currentItem];

  playerStatusTextField.playlistItem = currentItem;
  playerStatusTextField.status = kPlayerStatusPlaying;
}

- (void)trackFinished {
  [LastFM scrobble:_nowPlayingPlaylist.currentItem];
  [self next];
}

- (void)stop {
  [self setPlayButtonStyle:kPlayButtonStylePlay];
  [self disableTimer];
  [[MartinAppDelegate get].filePlayer stop];
  playerStatusTextField.status = kPlayerStatusStopped;
  _nowPlayingPlaylist = nil;
}

- (void)playOrPause {
  [self setNowPlayingPlaylistIfNecessary];

  if ([[MartinAppDelegate get].filePlayer stopped]) {
    if ([self willPlayQueuedItem] == NO) {
      [self startPlayingCurrentItem];
    }
  } else {
    [[MartinAppDelegate get].filePlayer togglePause];
    if ([[MartinAppDelegate get].filePlayer playing]) {
      [self setPlayButtonStyle:kPlayButtonStylePause];
      playerStatusTextField.status = kPlayerStatusPlaying;
    } else {
      [self setPlayButtonStyle:kPlayButtonStylePlay];
      playerStatusTextField.status = kPlayerStatusPaused;
    }
  }
}

- (void)next {
  [self setNowPlayingPlaylistIfNecessary];

  if ([self willPlayQueuedItem] == NO) {
    [self stopOrPlayWithTestObject:[_nowPlayingPlaylist moveToNextItem]];
  }
}

- (void)prev {
  [self setNowPlayingPlaylistIfNecessary];

  if ([MartinAppDelegate get].filePlayer.playing == YES && [MartinAppDelegate get].filePlayer.timeElapsed > 3) {
    [self startPlayingCurrentItem];
  } else {
    if (playingQueuedItem) {
      _nowPlayingPlaylist = [[MartinAppDelegate get].tabsManager.queue currentItemPlaylist];
      playingQueuedItem = NO;
      [self stopOrPlayWithTestObject:_nowPlayingPlaylist];
    } else {
      [self stopOrPlayWithTestObject:[_nowPlayingPlaylist moveToPrevItem]];
    }
  }
}

- (void)stopOrPlayWithTestObject:(id)o {
  if (o != nil) {
    [self startPlayingCurrentItem];
  } else {
    [self stop];
  }
}

- (void)startSeekTimerIfNecessaryWithItem:(PlaylistItem *)item {
  if (item.isURLStream) {
    [self disableTimer];
  } else {
    [self startSeekTimer];
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
  if (style == kPlayButtonStylePlay) {
    playOrPauseButton.image = [NSImage imageNamed:@"play"];
    playOrPauseButton.alternateImage = [NSImage imageNamed:@"play_h"];
  } else {
    playOrPauseButton.image = [NSImage imageNamed:@"pause"];
    playOrPauseButton.alternateImage = [NSImage imageNamed:@"pause_h"];
  }
}

#pragma mark - queue management

- (BOOL)willPlayQueuedItem {
  QueuePlaylist *queue = [MartinAppDelegate get].tabsManager.queue;

  if (playingQueuedItem) {
    _nowPlayingPlaylist = [queue currentItemPlaylist];
    playingQueuedItem = NO;
    [queue removeFirstItem];
    [[MartinAppDelegate get].playlistTableManager queueChanged];
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
  [self prev];
}

- (IBAction)playOrPausePressed:(id)sender {
  [self playOrPause];
}

- (IBAction)nextPressed:(id)sender {
  [self next];
}

- (IBAction)stopPressed:(id)sender {
  [self stop];
}

- (void)setNowPlayingPlaylistIfNecessary {
  if (_nowPlayingPlaylist == nil) {
    _nowPlayingPlaylist = [MartinAppDelegate get].tabsManager.selectedPlaylist;
  }
}

- (void)playItemWithIndex:(int)index {
  _nowPlayingPlaylist = [[MartinAppDelegate get].tabsManager selectedPlaylist];

  if (_nowPlayingPlaylist == [MartinAppDelegate get].tabsManager.queue) {
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

#pragma mark - saving state

- (void)storePlayerState {
  FilePlayer *filePlayer = [MartinAppDelegate get].filePlayer;
  [DefaultsManager setObject:@(filePlayer.volume) forKey:kDefaultsKeyVolume];

  PlayerStatus status = playerStatusTextField.status;

  // TODO: martin can't remember seek position of an item that doesn't belong to any playlist
  // we could remember a library id or a filename to solve this
  if ([MartinAppDelegate get].playerController.nowPlayingPlaylist == nil) {
    status = kPlayerStatusStopped;
  }

  [DefaultsManager setObject:@(status) forKey:kDefaultsKeyPlayerState];
  if (status != kPlayerStatusStopped) {
    [DefaultsManager setObject:@(filePlayer.seek) forKey:kDefaultsKeySeekPosition];
  }
}

- (void)restorePlayerState {
  PlayerStatus savedStatus = [[DefaultsManager objectForKey:kDefaultsKeyPlayerState] intValue];

  if (savedStatus == kPlayerStatusStopped) {
    playerStatusTextField.status = kPlayerStatusStopped;
  } else {
    [self setNowPlayingPlaylistIfNecessary];

    PlaylistItem *currentItem = _nowPlayingPlaylist.currentItem;
    
    FilePlayer *filePlayer = [MartinAppDelegate get].filePlayer;
    [filePlayer prepareForPlayingItem:currentItem];
    filePlayer.seek = [[DefaultsManager objectForKey:kDefaultsKeySeekPosition] doubleValue];
    
    [self startSeekTimerIfNecessaryWithItem:currentItem];
    
    playerStatusTextField.playlistItem = currentItem;
    playerStatusTextField.status = kPlayerStatusPaused;
  }
}

#pragma mark - shuffle and repeat

- (void)setShuffle:(BOOL)shuffle {
  _shuffle = shuffle;
  [DefaultsManager setObject:@(_shuffle) forKey:kDefaultsKeyShuffle];
  shuffleButton.state = shuffle;
}

- (void)setRepeat:(BOOL)repeat {
  _repeat = repeat;
  [DefaultsManager setObject:@(_repeat) forKey:kDefaultsKeyRepeat];
  repeatButton.state = repeat;
}

- (IBAction)repeatPressed:(id)sender {
  self.repeat = !self.repeat;
}

- (IBAction)shufflePressed:(id)sender {
  self.shuffle = !self.shuffle;
}

@end
