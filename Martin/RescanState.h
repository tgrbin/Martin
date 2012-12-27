//
//  RescanState.h
//  Martin
//
//  Created by Tomislav Grbin on 12/27/12.
//
//

#import <Foundation/Foundation.h>

#define kLibraryRescanStartedNotification @"LibraryRescanStartedNotification"
#define kLibraryRescanFinishedNotification @"LibraryRescanFinishedNotification"
#define kLibraryRescanStateChangedNotification @"LibraryRescanStateChangedNotification"

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

- (void)setupProgressIndicator:(NSProgressIndicator *)pi andTextField:(NSTextField *)tf;

@end
