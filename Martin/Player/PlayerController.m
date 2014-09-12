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
#import "NotificationsGenerator.h"
#import "Player.h"

NSString * const kPlayerEventNotification = @"PlayerEventNotification";

typedef enum {
  kPlayButtonStylePlay,
  kPlayButtonStylePause
} PlayButtonStyle;

@interface PlayerController() <PlayerDelegate>

@property (nonatomic, strong) Player *player;

@property (nonatomic, weak) PlaylistItem *currentItem;

@end

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
  
  self.shuffle = [[DefaultsManager objectForKey:kDefaultsKeyShuffle] boolValue];
  self.repeat = [[DefaultsManager objectForKey:kDefaultsKeyRepeat] boolValue];
  self.volume = [[DefaultsManager objectForKey:kDefaultsKeyVolume] doubleValue];
}

- (BOOL)nowPlayingItemFromPlaylist:(Playlist *)playlist {
  if (self.player.stopped == NO) {
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
  if (_nowPlayingPlaylist.numberOfItems == 0) {
    return;
  }
  
  if (_nowPlayingPlaylist.currentItem == nil) {
    [_nowPlayingPlaylist moveToNextItem];
  }

  if (playingQueuedItem) {
    Playlist *p = [(QueuePlaylist *)_nowPlayingPlaylist currentItemPlaylist];
    if (p) {
      [p findAndSetCurrentItemTo:_nowPlayingPlaylist.currentItem];
      [p addCurrentItemToAlreadyPlayedItems];
    }
  }

  self.currentItem = _nowPlayingPlaylist.currentItem;
  
  [_nowPlayingPlaylist addCurrentItemToAlreadyPlayedItems];
  
  [self startSeekTimerIfNecessaryWithItem:self.currentItem];
  
  [self createPlayerForCurrentItem];
  
  [[NotificationsGenerator shared] showWithItem:self.currentItem];

  [self.player play];
  
  [self setPlayButtonStyle:kPlayButtonStylePause];
  [LastFM updateNowPlaying:self.currentItem];

  playerStatusTextField.playlistItem = self.currentItem;
  playerStatusTextField.status = kPlayerStatusPlaying;

  [self postPlayerEvent];
}

- (void)trackFinished {
  [self next];
}

- (void)stop {
  [self setPlayButtonStyle:kPlayButtonStylePlay];
  [self disableTimer];
  
  [self.player stop];
  
  playerStatusTextField.status = kPlayerStatusStopped;
  _nowPlayingPlaylist = nil;
  
  [self postPlayerEvent];
}

- (void)playOrPause {
  [self setNowPlayingPlaylistIfNecessary];

  if (self.player.stopped == YES) {
    if ([self willPlayQueuedItem] == NO) {
      [self startPlayingCurrentItem];
    }
  } else {
    [self.player togglePause];
    
    if (self.player.playing == YES) {
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

  if (self.player.playing == YES && self.player.secondsElapsed > 3) {
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
  if (self.player.stopped == YES) {
    [self disableTimer];
  } else {
    seekSlider.doubleValue = self.player.seek;
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

- (void)createPlayerForCurrentItem {
  [self.player stop];
  
  self.player = [Player playerWithURLString:self.currentItem.filename
                                andDelegate:self];
  
  self.player.volume = [self volumeFunction:self.volume];
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
  self.player.seek = sender.doubleValue;
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

- (void)postPlayerEvent {
  [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerEventNotification
                                                      object:self
                                                    userInfo:nil];
}

#pragma mark - saving state

- (void)storePlayerState {
  [DefaultsManager setObject:@(self.volume) forKey:kDefaultsKeyVolume];

  PlayerStatus status = playerStatusTextField.status;

  // TODO: martin can't remember seek position of an item that doesn't belong to any playlist
  // we could remember a library id or a filename to solve this
  if (self.nowPlayingPlaylist == nil) {
    status = kPlayerStatusStopped;
  }

  [DefaultsManager setObject:@(status) forKey:kDefaultsKeyPlayerState];
  if (status != kPlayerStatusStopped) {
    [DefaultsManager setObject:@(self.player.seek) forKey:kDefaultsKeySeekPosition];
  }
}

- (void)restorePlayerState {
  PlayerStatus savedStatus = [[DefaultsManager objectForKey:kDefaultsKeyPlayerState] intValue];

  if (savedStatus == kPlayerStatusStopped) {
    playerStatusTextField.status = kPlayerStatusStopped;
  } else {
    [self setNowPlayingPlaylistIfNecessary];

    self.currentItem = _nowPlayingPlaylist.currentItem;
    
    [self createPlayerForCurrentItem];
    
    self.player.seek = [[DefaultsManager objectForKey:kDefaultsKeySeekPosition] doubleValue];
    
    [self startSeekTimerIfNecessaryWithItem:self.currentItem];
    
    playerStatusTextField.playlistItem = self.currentItem;
    playerStatusTextField.status = kPlayerStatusPaused;
    
    [self postPlayerEvent];
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

#pragma mark - volume

static const double kVolumeChangeStep = 0.05;

- (CGFloat)volumeFunction:(CGFloat)v {
  // logarithmic scale for volume, read somewhere that it should be done this way
  return v * v * v;
}

- (void)setVolume:(CGFloat)volume {
  _volume = volume;
  
  self.player.volume = [self volumeFunction:_volume];
}

- (IBAction)volumeUp:(id)sender {
  self.volume = MIN(_volume + kVolumeChangeStep, 1);
}

- (IBAction)volumeDown:(id)sender {
  self.volume = MAX(_volume - kVolumeChangeStep, 0);
}

#pragma mark - player delegate

- (void)errorPlayingItem {
  NSString *streamName = [self.currentItem tagValueForIndex:kTagIndexTitle];
  
  [self stop];
  
  [[NSAlert alertWithMessageText:[NSString stringWithFormat:@"Couldn't play '%@' :(", streamName]
                   defaultButton:@"OK"
                 alternateButton:nil
                     otherButton:nil
       informativeTextWithFormat:@""]
    runModal];
}

- (void)finishedPlayingItem {
  [LastFM scrobble:self.currentItem];
  [self next];
}

@end
