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

#include <SFBAudioEngine/AudioPlayer.h>
#include <SFBAudioEngine/CoreAudioOutput.h>

NSString * const kFilePlayerPlayedItemNotification = @"FilePlayerPlayedItemNotification";
NSString * const kFilePlayerEventNotification = @"FilePlayerEventNotification";

// TODO: refactor this into two classes

@interface FilePlayer() <
  STKAudioPlayerDelegate,
  NSSoundDelegate
>
@end

@implementation FilePlayer {
  SFB::Audio::Player *audioPlayer;
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
    audioPlayer = new SFB::Audio::Player();
  }
  
  self.volume = _volume;

  _playing = NO;
  _stopped = NO;

  if (prepare == NO) {
    if (audioPlayer) {
      NSURL *url = [NSURL fileURLWithPath:item.filename isDirectory:NO];
      audioPlayer->Play((__bridge CFURLRef) url);
      
      audioPlayer->SetRenderingFinishedBlock(^(const SFB::Audio::Decoder &decoder) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self stop];
          [self postNotification:kFilePlayerPlayedItemNotification];
        });
      });
      
    } else {
      [urlStreamPlayer play:item.filename];
    }
    
    _playing = YES;
  }

  playlistItem = item;
  [self postNotification:kFilePlayerEventNotification];
}

- (PlaylistItem *)currentItem {
  return playlistItem;
}

- (void)togglePause {
  if (audioPlayer) {
    audioPlayer->PlayPause();
  } else {
    if (_playing) {
      [urlStreamPlayer stop];
    } else {
      [urlStreamPlayer play:playlistItem.filename];
    }
  }
  
  _playing = !_playing;
}

- (void)stop {
  if (audioPlayer) {
    audioPlayer->Stop();
    delete audioPlayer;
    audioPlayer = nullptr;
  } else {
    [urlStreamPlayer stop];
    urlStreamPlayer = nil;
  }
  
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
  
  if (audioPlayer) {
    SFB::Audio::CoreAudioOutput &output = (SFB::Audio::CoreAudioOutput&) audioPlayer->GetOutput();
    output.SetVolume(actualVolume);
  } else {
    urlStreamPlayer.volume = actualVolume;
  }
}

- (void)setSeek:(double)seek {
  if (audioPlayer) {
    audioPlayer->SeekToPosition(seek);
  }
}

- (double)seek {
  SInt64 currentFrame, totalFrames;
  
  if (audioPlayer && audioPlayer->GetPlaybackPosition(currentFrame, totalFrames)) {
    return (double)currentFrame / totalFrames;
  } else {
    return 0;
  }
}

- (double)timeElapsed {
  SInt64 currentFrame, totalFrames;
  CFTimeInterval currentTime, totalTime;

  if (audioPlayer && audioPlayer->GetPlaybackPositionAndTime(currentFrame, totalFrames, currentTime, totalTime)) {
    return currentTime;
  } else {
    return 0;
  }
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
  
  [[NSAlert alertWithMessageText:[NSString stringWithFormat:@"Couldn't play '%@' :(", streamName]
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

#pragma mark - helper

- (void)postNotification:(NSString *)notification {
  [[NSNotificationCenter defaultCenter] postNotificationName:notification object:playlistItem];
}

@end
