//
//  RescanState.m
//  Martin
//
//  Created by Tomislav Grbin on 12/27/12.
//
//

#import "RescanState.h"

@implementation RescanState

static RescanState *sharedState;

+ (void)initialize {
  sharedState = [RescanState new];
}

+ (RescanState *)sharedState {
  return sharedState;
}

- (int)currentPercentage {
  if (_numberOfSongsFound == 0) return 0;
  return (int) (100. * _alreadyRescannedSongs / _songsToRescan);
}

- (void)setAlreadyRescannedSongs:(int)alreadyRescannedSongs {
  int lastPercentage = self.currentPercentage;
  _alreadyRescannedSongs = alreadyRescannedSongs;
  if (self.currentPercentage != lastPercentage) [self post:kLibraryRescanStateChangedNotification];
}

- (void)setState:(RescanStateEnum)state {
  if (_state == state) return;

  _state = state;
  [self post:kLibraryRescanStateChangedNotification];

  if (_state == kRescanStateTraversing) {
    _alreadyRescannedSongs = 0;
    _numberOfSongsFound = 0;
    _songsToRescan = 0;
    [self post:kLibraryRescanStartedNotification];
  } else if (_state == kRescanStateIdle) [self post:kLibraryRescanFinishedNotification];
}

- (void)post:(NSString *)notifName {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:notifName object:nil];
  });
}

- (NSString *)message {
  if (_state == kRescanStateTraversing) return @"Traversing folders";
  if (_state == kRescanStateReadingID3s) {
    if (_songsToRescan == _numberOfSongsFound) return [NSString stringWithFormat:@"Rescanning %d songs", _songsToRescan];
    else return [NSString stringWithFormat:@"%d songs in library, %d needs rescan", _numberOfSongsFound, _songsToRescan];
  }
  if (_state == kRescanStateReloadingLibrary) return @"Reloading library";
  return @"";
}

- (void)setupProgressIndicator:(NSProgressIndicator *)pi andTextField:(NSTextField *)tf {
  if (_state == kRescanStateIdle) {
    tf.hidden = pi.hidden = YES;
  } else {
    tf.hidden = pi.hidden = NO;
    tf.stringValue = self.message;

    if (_state == kRescanStateReadingID3s) {
      pi.indeterminate = NO;
      pi.doubleValue = self.currentPercentage;
    } else {
      pi.indeterminate = YES;
      [pi startAnimation:nil];
    }
  }
}

@end
