//
//  AudioPlayer.h
//  Martin
//
//  Created by Tomislav Grbin on 06/09/14.
//
//

#import <Foundation/Foundation.h>

@protocol PlayerDelegate

- (void)errorPlayingItem;
- (void)finishedPlayingItem;

@end

@interface Player : NSObject

+ (Player *)playerWithURLString:(NSString *)urlString
                    andDelegate:(id<PlayerDelegate>)delegate;

@property (nonatomic, readonly, copy) NSString *urlString;
@property (nonatomic, readonly, weak) id<PlayerDelegate> delegate;

@property (nonatomic, readonly) BOOL playing;
@property (nonatomic, readonly) BOOL stopped;

@property (nonatomic, assign) CGFloat volume; // between
@property (nonatomic, assign) CGFloat seek;   // 0 and 1

@property (nonatomic, readonly) CGFloat secondsElapsed;

- (void)play;
- (void)togglePause;
- (void)stop;

@end
