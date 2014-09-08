//
//  AudioPlayer.m
//  Martin
//
//  Created by Tomislav Grbin on 06/09/14.
//
//

#import "Player.h"

#import "SFBPlayer.h"
#import "StreamingKitPlayer.h"

#import "DefaultsManager.h"
#import "NSString+Stream.h"

@interface Player()

@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, weak) id<PlayerDelegate> delegate;

@end

@implementation Player

+ (Player *)playerWithURLString:(NSString *)urlString andDelegate:(id<PlayerDelegate>)delegate {
  Class playerClass =
    [urlString isURL]?
    [StreamingKitPlayer class]:
    [SFBPlayer class];
  
  Player *player = [playerClass new];
  player.urlString = urlString;
  player.delegate = delegate;
  return player;
}

- (void)play {
  _stopped = NO;
  _playing = YES;
}

- (void)togglePause {
  _playing = !_playing;
}

- (void)stop {
  _stopped = YES;
  _playing = NO;
}

@end
