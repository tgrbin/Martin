//
//  StreamingKitPlayer.m
//  Martin
//
//  Created by Tomislav Grbin on 06/09/14.
//
//

#import "StreamingKitPlayer.h"
#import "MartinAppDelegate.h"

#import "STKAudioPlayer.h"

@interface StreamingKitPlayer() <STKAudioPlayerDelegate>
@end

@implementation StreamingKitPlayer {
  STKAudioPlayer *player;
}

- (id)init {
  if (self = [super init]) {
    player = [STKAudioPlayer new];
    player.delegate = self;
  }
  return self;
}

- (void)play {
  [super play];
  
  [player play:self.urlString];
}

- (void)togglePause {
  BOOL wasPlaying = self.playing;
  
  [super togglePause];
  
  if (wasPlaying == YES) {
    [player stop];
  } else {
    [player play:self.urlString];
  }
}

- (void)stop {
  [super stop];
  
  if (player != nil) {
    [player stop];
    player = nil;
  }
}

- (void)setVolume:(CGFloat)volume {
  player.volume = volume;
}

#pragma mark - delegate

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

- (void)audioPlayer:(STKAudioPlayer*)audioPlayer
    unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
  [self.delegate errorPlayingItem];
}

@end
