//
//  PlayerStatusTextField.h
//  Martin
//
//  Created by Tomislav Grbin on 9/14/13.
//
//

#import <Cocoa/Cocoa.h>

typedef enum {
  kPlayerStatusStopped,
  kPlayerStatusPaused,
  kPlayerStatusPlaying
} PlayerStatus;

@class PlaylistItem;

@interface PlayerStatusTextField : NSTextField

@property (nonatomic, assign) PlayerStatus status;

@property (nonatomic, strong) PlaylistItem *playlistItem;

@end
