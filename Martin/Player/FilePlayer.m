//
//  FilePlayer.m
//  Martin
//
//  Created by Tomislav Grbin on 11/23/12.
//
//

#import "FilePlayer.h"
#import "PlaylistItem.h"
#import "DefaultsManager.h"
#import "NotificationsGenerator.h"

#import "STKAudioPlayer.h"

@interface FilePlayer() <STKAudioPlayerDelegate>
@end

@implementation FilePlayer {
  NSSound *sound;
  STKAudioPlayer *streamer;
  
  PlaylistItem *playlistItem;
}

- (void)awakeFromNib {
  _stopped = YES;
  self.volume = [[DefaultsManager objectForKey:kDefaultsKeyVolume] doubleValue];
}

- (void)startPlayingItem:(PlaylistItem *)item {
  [[NotificationsGenerator shared] showWithItem:item];
  [self playItem:item justPrepare:NO];
}

- (void)prepareForPlayingItem:(PlaylistItem *)item {
  [self playItem:item justPrepare:YES];
}

- (void)playItem:(PlaylistItem *)item justPrepare:(BOOL)prepare {
  [self stop];

  if (item.isURLStream == YES) {
    streamer = [STKAudioPlayer new];
    streamer.delegate = self;
  } else {
    sound = [[NSSound alloc] initWithContentsOfFile:item.filename byReference:YES];
    if (sound == nil) {
      NSLog(@"playing failed: %@", item.filename);
      return;
    }

    sound.delegate = self;
  }
  
  self.volume = _volume;

  _playing = NO;
  _stopped = NO;

  if (prepare == NO) {
    [sound play];
    [streamer play:item.filename];
    _playing = YES;
  }

  playlistItem = item;
  [self postNotification:kFilePlayerEventNotification];
}

- (PlaylistItem *)currentItem {
  return playlistItem;
}

- (void)togglePause {
  if (_playing) {
    [sound pause];
    [streamer pause];
  } else {
    if ([sound resume] == NO) {
      [sound play];
    }
    
    [streamer resume];
  }
  
  _playing = !_playing;
}

- (void)stop {
  [sound stop];
  sound = nil;
  
  [streamer stop];
  streamer = nil;
  
  playlistItem = nil;
  _stopped = YES;
  _playing = NO;
  [self postNotification:kFilePlayerEventNotification];
}

- (void)setVolume:(double)volume {
  _volume = volume;
  
  // logarithmic scale for volume, read somewhere that it should be done this way
  double cube = _volume * _volume * _volume;
  
  double actualVolume = (_volume == 0)? 0: MAX(cube, 0.001);
  
  sound.volume = actualVolume;
  streamer.volume = actualVolume;
}

- (void)setSeek:(double)seek {
  if (sound) {
    sound.currentTime = seek * sound.duration;
  }
}

- (double)seek {
  if (sound == nil || sound.duration == 0) {
    return 0;
  } else {
    return sound.currentTime / sound.duration;
  }
}

- (double)timeElapsed {
  return sound.currentTime;
}

#pragma mark - nssound delegate

- (void)sound:(NSSound *)s didFinishPlaying:(BOOL)success {
  if (success) {
    [self stop];
    [self postNotification:kFilePlayerPlayedItemNotification];
  }
}

- (void)postNotification:(NSString *)notification {
  [[NSNotificationCenter defaultCenter] postNotificationName:notification object:playlistItem];
}

#pragma mark - STKAudioPlayer delegate

/// Raised when an item has started playing
- (void)audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId {
}

/// Raised when an item has finished buffering (may or may not be the currently playing item)
/// This event may be raised multiple times for the same item if seek is invoked on the player
- (void)audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId {
}

/// Raised when the state of the player has changed
- (void)audioPlayer:(STKAudioPlayer*)audioPlayer
       stateChanged:(STKAudioPlayerState)state
      previousState:(STKAudioPlayerState)previousState
{
}

/// Raised when an item has finished playing
- (void)audioPlayer:(STKAudioPlayer*)audioPlayer
didFinishPlayingQueueItemId:(NSObject*)queueItemId
         withReason:(STKAudioPlayerStopReason)stopReason
        andProgress:(double)progress
        andDuration:(double)duration
{
}

/// Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlayer)
- (void)audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode {
}

#pragma mark - actions

static const double kVolumeChangeStep = 0.05;

- (IBAction)volumeUp:(id)sender {
  self.volume = MIN(_volume + kVolumeChangeStep, 1);
}

- (IBAction)volumeDown:(id)sender {
  self.volume = MAX(_volume - kVolumeChangeStep, 0);
}

@end
