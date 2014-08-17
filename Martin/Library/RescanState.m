//
//  RescanState.m
//  Martin
//
//  Created by Tomislav Grbin on 12/27/12.
//
//

#import "RescanState.h"

NSString * const kLibraryRescanStartedNotification = @"LibraryRescanStartedNotification";
NSString * const kLibraryRescanFinishedNotification = @"LibraryRescanFinishedNotification";
NSString * const kLibraryRescanStateChangedNotification = @"LibraryRescanStateChangedNotification";
NSString * const kLibraryRescanTreeReadyNotification = @"LibraryRescanTreeReadyNotification";

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

  if (state == kRescanStateReadingID3s && _state == kRescanStateReloadingLibrary) {
    [self post:kLibraryRescanTreeReadyNotification];
  }

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
  dispatch_sync(dispatch_get_main_queue(), ^{
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

- (void)setupProgressIndicator:(NSProgressIndicator *)pi
indeterminateProgressIndicator:(NSProgressIndicator *)ipi
                  andTextField:(NSTextField *)tf {
  if (_state == kRescanStateIdle) {
    if (tf.tag) {
      tf.stringValue = @"";
      ipi.hidden = pi.hidden = YES;
    } else {
      tf.hidden = pi.hidden = ipi.hidden = YES;
    }
  } else {
    tf.hidden = NO;
    tf.stringValue = self.message;

    if (_state == kRescanStateReadingID3s) {
      ipi.hidden = YES;
      pi.hidden = NO;
      pi.doubleValue = self.currentPercentage;
    } else {
      pi.hidden = YES;
      ipi.hidden = NO;
      [ipi startAnimation:nil];
    }
  }
}

@end
