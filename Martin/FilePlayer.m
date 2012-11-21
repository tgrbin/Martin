//
//  FilePlayer.m
//  Martin
//
//  Created by Tomislav Grbin on 11/23/12.
//
//

#import "FilePlayer.h"
#import "PlaylistItem.h"

@implementation FilePlayer

static FilePlayer *sharedPlayer = nil;

+ (FilePlayer *)sharedPlayer {
  return sharedPlayer;
}

- (void)awakeFromNib {
  sharedPlayer = self;
  _stopped = YES;
  self.volume = 0.5;
}

- (void)startPlayingItem:(PlaylistItem *)item {
  [self stop];
  
  sound = [[NSSound alloc] initWithContentsOfFile:item.filename byReference:YES];
  sound.delegate = self;
  sound.volume = _volume;
  [sound play];
  
  _playing = YES;
  _stopped = NO;
  
  playlistItem = item;
  [[NSNotificationCenter defaultCenter] postNotificationName:kFilePlayerStartedPlayingNotification object:item];
}

- (void)togglePause {
  if (_playing) [sound pause];
  else [sound resume];
  _playing = !_playing;
}

- (void)stop {
  if (sound) {
    [sound stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:kFilePlayerStoppedNotification object:playlistItem];
  }
  sound = nil;
  playlistItem = nil;
  _stopped = YES;
  _playing = NO;
}

- (void)setVolume:(double)volume {
  _volume = volume;
  if (sound) sound.volume = _volume;
}

- (void)setSeek:(double)seek {
  if (sound) sound.currentTime = seek * sound.duration;
}

- (double)seek {
  if (sound == nil || sound.duration == 0) return 0;
  return sound.currentTime / sound.duration;
}

#pragma mark - nssound delegate

- (void)sound:(NSSound *)s didFinishPlaying:(BOOL)success {
  sound = nil;
  if (success) {
    [self stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:kFilePlayerPlayedItemNotification object:playlistItem];
  }
}

@end
