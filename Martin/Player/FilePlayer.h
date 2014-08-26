//
//  FilePlayer.h
//  Martin
//
//  Created by Tomislav Grbin on 11/23/12.
//
//

#import <Foundation/Foundation.h>

extern NSString * const kFilePlayerPlayedItemNotification;
extern NSString * const kFilePlayerEventNotification;

@class PlaylistItem;

@interface FilePlayer : NSObject

@property (nonatomic, assign) BOOL playing;
@property (nonatomic, assign) BOOL stopped;

// between 0 and 1
@property (nonatomic, assign) double volume;

// between 0 and 1
- (void)setSeek:(double)seek;
- (double)seek;

- (double)timeElapsed;

- (void)startPlayingItem:(PlaylistItem *)item;
- (void)prepareForPlayingItem:(PlaylistItem *)item;
- (void)togglePause;
- (void)stop;

- (PlaylistItem *)currentItem;

@end
