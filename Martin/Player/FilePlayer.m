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

@implementation FilePlayer {
  NSSound *sound;
  PlaylistItem *playlistItem;
}

- (void)awakeFromNib {
  _stopped = YES;
  self.volume = [[DefaultsManager objectForKey:kDefaultsKeyVolume] doubleValue];
}

- (void)startPlayingItem:(PlaylistItem *)item {
  [self playItem:item justPrepare:NO];
}

- (void)prepareForPlayingItem:(PlaylistItem *)item {
  [self playItem:item justPrepare:YES];
}

- (void)playItem:(PlaylistItem *)item justPrepare:(BOOL)prepare {
  [self stop];

  sound = [[NSSound alloc] initWithContentsOfFile:item.filename byReference:YES];
  if (sound == nil) {
    NSLog(@"playing failed: %@", item.filename);
    return;
  }

  sound.delegate = self;
  self.volume = _volume;

  _playing = NO;
  _stopped = NO;

  if (prepare == NO) {
    [sound play];
    _playing = YES;
  }

  playlistItem = item;
  [self postNotification:kFilePlayerEventNotification];
}

- (void)togglePause {
  if (_playing) {
    [sound pause];
  } else {
    if ([sound resume] == NO) {
      [sound play];
    }
  }
  _playing = !_playing;
}

- (void)stop {
  if (sound) {
    [sound stop];
    [self postNotification:kFilePlayerEventNotification];
  }
  sound = nil;
  playlistItem = nil;
  _stopped = YES;
  _playing = NO;
}

- (void)setVolume:(double)volume {
  _volume = volume;
  if (sound) {
    // logarithmic scale for volume, read in Cog player source that it should be done this way
    double x = _volume * _volume * _volume;
    sound.volume = (_volume == 0)? 0: MAX(x, 0.001);
  }
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

#pragma mark - context menu actions

static const double kVolumeChangeStep = 0.05;

- (IBAction)volumeUp:(id)sender {
  self.volume = MIN(_volume + kVolumeChangeStep, 1);
}

- (IBAction)volumeDown:(id)sender {
  self.volume = MAX(_volume - kVolumeChangeStep, 0);
}

@end
