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
#import "MartinAppDelegate.h"
#import "STKAudioPlayer.h"

NSString * const kFilePlayerPlayedItemNotification = @"FilePlayerPlayedItemNotification";
NSString * const kFilePlayerEventNotification = @"FilePlayerEventNotification";

@interface FilePlayer() <STKAudioPlayerDelegate>
@end

@implementation FilePlayer {
  NSSound *sound;
  STKAudioPlayer *urlStreamPlayer;
  
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
    urlStreamPlayer = [STKAudioPlayer new];
    urlStreamPlayer.delegate = self;
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
    [urlStreamPlayer play:item.filename];
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
    
    [urlStreamPlayer stop];
  } else {
    if ([sound resume] == NO) {
      [sound play];
    }
    
    [urlStreamPlayer play:playlistItem.filename];
  }
  
  _playing = !_playing;
}

- (void)stop {
  [sound stop];
  sound = nil;
  
  [urlStreamPlayer stop];
  urlStreamPlayer = nil;
  
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
  urlStreamPlayer.volume = actualVolume;
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

- (void)audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId {}

- (void)audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId {}

- (void)audioPlayer:(STKAudioPlayer*)audioPlayer
       stateChanged:(STKAudioPlayerState)state
      previousState:(STKAudioPlayerState)previousState
{
  if (state == STKAudioPlayerStateBuffering) {
    ++[MartinAppDelegate get].martinBusy;
  }
  
  if (previousState == STKAudioPlayerStateBuffering) {
    --[MartinAppDelegate get].martinBusy;
  }
}

- (void)audioPlayer:(STKAudioPlayer*)audioPlayer
didFinishPlayingQueueItemId:(NSObject*)queueItemId
         withReason:(STKAudioPlayerStopReason)stopReason
        andProgress:(double)progress
        andDuration:(double)duration
{}

- (void)audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
  NSString *streamName = [playlistItem tagValueForIndex:kTagIndexTitle];
  
  [[MartinAppDelegate get].playerController stop];
  
  [[NSAlert alertWithMessageText:[NSString stringWithFormat:@"Sorry, couldn't play '%@'", streamName]
                   defaultButton:@"OK"
                 alternateButton:nil
                     otherButton:nil
       informativeTextWithFormat:@""]
    runModal];
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
