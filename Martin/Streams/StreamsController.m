//
//  StreamsController.m
//  Martin
//
//  Created by Tomislav Grbin on 17/08/14.
//
//

#import "StreamsController.h"
#import "DefaultsManager.h"
#import "Stream.h"

#import "NSString+Stream.h"

NSString * const kStreamsUpdatedNotification = @"kStreamsUpdatedNotification";

@interface StreamsController()

@property (nonatomic, strong) NSArray *streams;

@end

@implementation StreamsController

- (id)init {
  if (self = [super init]) {
    [self loadStreamsIfNecessary];
  }
  return self;
}

- (Stream *)streamWithURLString:(NSString *)urlString {
  urlString = [urlString URLify];
  
  for (Stream *stream in _streams) {
    if ([stream.urlString isEqualToString:urlString]) {
      return stream;
    }
  }
  
  return nil;
}

- (Stream *)createOrReturnStreamWithURLString:(NSString *)urlString {
  Stream *stream = [self streamWithURLString:urlString];
  
  if (stream == nil) {
    stream = [self createStreamWithURLString:urlString];
    [stream sendRequestForStreamNameWithCompletionBlock:nil];
  }
  
  return stream;
}

- (Stream *)createStreamWithURLString:(NSString *)urlString {
  Stream *stream = [[Stream alloc] initWithURLString:[urlString URLify]];
  
  [self observeStream:stream];
  
  [(NSMutableArray *)_streams addObject:stream];
  
  [self streamsUpdated];
  
  return stream;
}

- (void)observeStream:(Stream *)stream {
  [stream addObserver:self forKeyPath:@"name" options:0 context:nil];
  [stream addObserver:self forKeyPath:@"urlString" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"name"] || [keyPath isEqualToString:@"urlString"]) {
    [self streamsUpdated];
  }
}

- (void)removeStream:(Stream *)stream {
  [(NSMutableArray *)_streams removeObject:stream];
  [stream removeObserver:self forKeyPath:@"name"];
  [stream removeObserver:self forKeyPath:@"urlString"];
  
  [self streamsUpdated];
}

- (void)reorderStreamAtIndex:(NSInteger)index toNewIndex:(NSInteger)newIndex {
  Stream *stream = _streams[index];
  [(NSMutableArray *)_streams removeObjectAtIndex:index];
  [(NSMutableArray *)_streams insertObject:stream atIndex:newIndex];
  [self streamsUpdated];
}

- (void)streamsUpdated {
  [[NSNotificationCenter defaultCenter] postNotificationName:kStreamsUpdatedNotification
                                                      object:nil
                                                    userInfo:nil];
}

#pragma mark - persistence

- (void)loadStreamsIfNecessary {
  if (_streams == nil) {
    _showStreamsInLibraryPane = [[DefaultsManager objectForKey:kDefaultsKeyShowStreamsInLibraryPane] boolValue];
    
    _streams = [NSMutableArray new];
    NSArray *streamsInfo = [DefaultsManager objectForKey:kDefaultsKeyStreams];
    for (NSDictionary *info in streamsInfo) {
      Stream *stream = [[Stream alloc] initWithURLString:info[@"url"]];
      stream.name = info[@"name"];
      
      [self observeStream:stream];
      
      [(NSMutableArray *)_streams addObject:stream];
    }
  }
}

- (void)storeStreams {
  NSMutableArray *streamsInfo = [NSMutableArray new];
  for (Stream *stream in _streams) {
    [streamsInfo addObject:@{
                             @"url": stream.urlString,
                             @"name": stream.name
                             }];
  }
  
  [DefaultsManager setObject:streamsInfo forKey:kDefaultsKeyStreams];
}

- (void)setShowStreamsInLibraryPane:(BOOL)showStreamsInLibraryPane {
  _showStreamsInLibraryPane = showStreamsInLibraryPane;
  
  [DefaultsManager setObject:@(showStreamsInLibraryPane)
                      forKey:kDefaultsKeyShowStreamsInLibraryPane];
}

@end
