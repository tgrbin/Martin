//
//  SFBEnginePlayer.m
//  Martin
//
//  Created by Tomislav Grbin on 06/09/14.
//
//

#import "SFBPlayer.h"

#include <SFBAudioEngine/AudioPlayer.h>
#include <SFBAudioEngine/CoreAudioOutput.h>

@implementation SFBPlayer {
  SFB::Audio::Player *player;
  
  CGFloat _seek;
  CGFloat _volume;
  
  BOOL startedPlaying;
}

- (id)init {
  if (self = [super init]) {
    player = new SFB::Audio::Player();
  }
  return self;
}

- (void)play {
  [super play];
  
  NSURL *url = [NSURL fileURLWithPath:self.urlString isDirectory:NO];
  
  player->Play((__bridge CFURLRef) url);
  
  player->SetRenderingFinishedBlock(^(const SFB::Audio::Decoder &decoder) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate finishedPlayingItem];
    });
  });
  
  self.volume = _volume;
  self.seek = _seek;
  
  startedPlaying = YES;
}

- (void)togglePause {
  [super togglePause];
  
  if (startedPlaying == NO) {
    [self play];
  } else {
    player->PlayPause();
  }
}

- (void)stop {
  [super stop];
  
  if (player) {
    player->Stop();
    delete player;
    player = nullptr;
  }
}

- (void)setSeek:(double)seek {
  _seek = seek;
  
  player->SeekToPosition(seek);
}

- (double)seek {
  SInt64 currentFrame, totalFrames;
  
  if (player->GetPlaybackPosition(currentFrame, totalFrames)) {
    _seek = (double)currentFrame / totalFrames;
  }
  
  return _seek;
}

- (double)secondsElapsed {
  SInt64 currentFrame, totalFrames;
  CFTimeInterval currentTime, totalTime;

  if (player->GetPlaybackPositionAndTime(currentFrame, totalFrames, currentTime, totalTime)) {
    return currentTime;
  } else {
    return 0;
  }
}

- (void)setVolume:(CGFloat)volume {
  _volume = volume;
  
  SFB::Audio::CoreAudioOutput &output = (SFB::Audio::CoreAudioOutput&) player->GetOutput();
  output.SetVolume(volume);
}

@end
