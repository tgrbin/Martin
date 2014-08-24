//
//  PlayerController.h
//  Martin
//
//  Created by Tomislav Grbin on 10/22/11.
//

#import <Foundation/Foundation.h>

@class Playlist;

@interface PlayerController : NSObject

@property (nonatomic, strong) Playlist *nowPlayingPlaylist;

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

@end
