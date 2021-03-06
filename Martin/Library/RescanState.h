//
//  RescanState.h
//  Martin
//
//  Created by Tomislav Grbin on 12/27/12.
//
//

#import <Foundation/Foundation.h>

extern NSString * const kLibraryRescanStartedNotification;
extern NSString * const kLibraryRescanFinishedNotification;
extern NSString * const kLibraryRescanStateChangedNotification;
extern NSString * const kLibraryRescanTreeReadyNotification;

typedef enum {
  kRescanStateIdle = 0,
  kRescanStateTraversing,
  kRescanStateReadingID3s,
  kRescanStateReloadingLibrary
} RescanStateEnum;

@interface RescanState : NSObject

+ (RescanState *)sharedState;

@property (nonatomic) RescanStateEnum state;

@property (nonatomic, readonly) NSString *message;

@property (nonatomic) int numberOfSongsFound;
@property (nonatomic) int songsToRescan;
@property (nonatomic) int alreadyRescannedSongs;
@property (nonatomic, readonly) int currentPercentage;

- (void)setupProgressIndicator:(NSProgressIndicator *)pi
indeterminateProgressIndicator:(NSProgressIndicator *)ipi
                  andTextField:(NSTextField *)tf;

@end
