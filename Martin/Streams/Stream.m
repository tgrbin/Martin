//
//  Stream.m
//  Martin
//
//  Created by Tomislav Grbin on 17/08/14.
//
//

#import "Stream.h"
#import "PlaylistItem.h"
#import "Tags.h"
#import "StreamNameGetter.h"

@interface Stream ()

@property (nonatomic, strong) StreamNameGetter *nameGetter;

@end

@implementation Stream

- (instancetype)initWithURLString:(NSString *)urlString {
  if (self = [super init]) {
    _urlString = urlString;
    _name = [self defaultName];
  }
  return self;
}

- (NSString *)defaultName {
  NSURL *url = [NSURL URLWithString:_urlString];
  return url.host ?: @"";
}

- (PlaylistItem *)createPlaylistItem {
  return [[PlaylistItem alloc] initWithStream:self];
}

+ (Tags *)createTagsFromStream:(Stream *)stream {
  NSMutableArray *tagsArray = [NSMutableArray new];
  for (int i = 0; i < kNumberOfTags; ++i) {
    [tagsArray addObject:@""];
  }
  
  tagsArray[kTagIndexTitle] = [stream.name copy];
  
  return [Tags createTagsFromArray:tagsArray];
}

- (void)sendRequestForStreamNameWithCompletionBlock:(void (^)(StreamNameRequestOutcome))block {
  __weak Stream *weakSelf = self;
  _nameGetter = [[StreamNameGetter alloc] initWithURLString:_urlString
                                                   andBlock:^(NSString *streamName) {
                                                     
                                                     StreamNameRequestOutcome outcome;
                                                     
                                                     if (streamName == nil) {
                                                       outcome = kStreamNameRequestOutcomeConnectionFailed;
                                                     } else if (streamName.length == 0) {
                                                       outcome = kStreamNameRequestOutcomeNoName;
                                                     } else {
                                                       weakSelf.name = streamName;
                                                       outcome = kStreamNameRequestOutcomeSuccessfulyUpdatedName;
                                                     }
                                                     
                                                     if (block) {
                                                       block(outcome);
                                                     }
                                                   }];
  [_nameGetter start];
}

- (void)dealloc {
  [_nameGetter cancel];
}

- (void)setName:(NSString *)name {
  [_nameGetter cancel];
  
  [super willChangeValueForKey:@"name"];
  _name = [name copy];
  [super didChangeValueForKey:@"name"];
}

- (void)setUrlString:(NSString *)urlString {
  [_nameGetter cancel];
  
  [super willChangeValueForKey:@"urlString"];
  _urlString = [urlString copy];
  [super didChangeValueForKey:@"urlString"];
}

@end
