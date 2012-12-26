//
//  FilePlayer.h
//  Martin
//
//  Created by Tomislav Grbin on 11/23/12.
//
//

#import <Foundation/Foundation.h>

#define kFilePlayerStartedPlayingNotification @"FilePlayerStartedPlayingNotification"
#define kFilePlayerStoppedPlayingNotification @"FilePlayerStoppedPlayingNotification"
#define kFilePlayerPlayedItemNotification @"FilePlayerPlayedItemNotification"
#define kFilePlayerEventNotification @"FilePlayerEventNotification"

@class PlaylistItem;

@interface FilePlayer : NSObject <NSSoundDelegate> {
  NSSound *sound;
  PlaylistItem *playlistItem;
}

+ (FilePlayer *)sharedPlayer;

@property (nonatomic, assign) BOOL playing;
@property (nonatomic, assign) BOOL stopped;

// between 0 and 1
@property (nonatomic, assign) double volume;

- (void)setSeek:(double)seek;
- (double)seek;

- (void)startPlayingItem:(PlaylistItem *)item;
- (void)togglePause;
- (void)stop;

@end
