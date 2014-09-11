//
//  NativePlayer.m
//  Martin
//
//  Created by Tomislav Grbin on 11/09/14.
//
//

#import "NativePlayer.h"

@interface NativePlayer() <NSSoundDelegate>
@end

@implementation NativePlayer {
  NSSound *sound;
  
  CGFloat _volume;
  CGFloat _seek;
  
  BOOL startedPlaying;
}

- (void)play {
  [super play];
  
  sound = [[NSSound alloc] initWithContentsOfFile:self.urlString
                                      byReference:YES];
  if (sound == nil) {
    [self.delegate errorPlayingItem];
  } else {
    sound.delegate = self;
    self.volume = _volume;
    self.seek = _seek;
    [sound play];
  }
  
  startedPlaying = YES;
}

- (void)togglePause {
  BOOL wasPlaying = self.playing;
  
  [super togglePause];
  
  if (startedPlaying == NO) {
    [self play];
  } else {
    if (wasPlaying == YES) {
      [sound pause];
    } else {
      [sound resume];
    }
  }
}

- (void)stop {
  [super stop];
  
  [sound stop];
  sound = nil;
}

- (void)setVolume:(CGFloat)volume {
  _volume = volume;
  
  sound.volume = volume;
}

- (void)setSeek:(CGFloat)seek {
  _seek = seek;
  
  sound.currentTime = seek * sound.duration;
}

- (CGFloat)seek {
  if (sound != nil && sound.duration > 0) {
    _seek = sound.currentTime / sound.duration;
  }
  
  return _seek;
}

- (CGFloat)timeElapsed {
  return sound.currentTime;
}

#pragma mark - nssound delegate

- (void)sound:(NSSound *)s didFinishPlaying:(BOOL)success {
  if (success == YES) {
    [self stop];
    [self.delegate finishedPlayingItem];
  }
  
  // success == NO happens when item is stopped,
  // and is handled elsewhere
}

@end
