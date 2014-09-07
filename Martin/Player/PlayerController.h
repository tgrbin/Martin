//
//  PlayerController.h
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//

#import <Foundation/Foundation.h>

extern NSString * const kPlayerEventNotification;

@class Playlist;
@class PlaylistItem;

@interface PlayerController : NSObject

@property (nonatomic, strong) Playlist *nowPlayingPlaylist;

@property (nonatomic, readonly, weak) PlaylistItem *currentItem;

- (BOOL)nowPlayingItemFromPlaylist:(Playlist *)playlist;

- (void)playSelectedPlaylist;
- (void)playItemWithIndex:(int)index;

// used only by GlobalShortcuts and MediaKeyManager
- (void)playOrPause;
- (void)next;
- (void)prev;
- (void)stop;

- (void)storePlayerState;
- (void)restorePlayerState;

@property (nonatomic, assign) BOOL shuffle;
@property (nonatomic, assign) BOOL repeat;

@property (nonatomic, assign) CGFloat volume;

@end
