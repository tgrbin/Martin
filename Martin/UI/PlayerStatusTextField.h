//
//  PlayerStatusTextField.h
//  Martin
//
//  Created by Tomislav Grbin on 9/14/13.
//
//

#import <Cocoa/Cocoa.h>

typedef enum {
  kTextFieldStatusStopped,
  kTextFieldStatusPaused,
  kTextFieldStatusPlaying
} TextFieldStatus;

@class PlaylistItem;

@interface PlayerStatusTextField : NSTextField

@property (nonatomic, assign) TextFieldStatus status;

@property (nonatomic, strong) PlaylistItem *playlistItem;

@end
