//
//  ID3ReadOperation.m
//  Martin
//
//  Created by Tomislav Grbin on 3/10/13.
//
//

#import "ID3ReadOperation.h"
#import "ID3Reader.h"
#import "PlaylistItem.h"

@interface ID3ReadOperation ()
@property (nonatomic, assign) PlaylistItem *playlistItem;
@end

@implementation ID3ReadOperation

- (id)initWithPlaylistItem:(PlaylistItem *)playlistItem {
  if (self = [super init]) {
    _playlistItem = playlistItem;
  }
  return self;
}

- (void)main {
  if (self.isCancelled) return;

  @autoreleasepool {
    ID3Reader *id3 = [[ID3Reader alloc] initWithFile:_playlistItem.filename];
    if (id3 != nil) {
      
      if (self.isCancelled) return;
      
      _playlistItem.lengthInSeconds = id3.lengthInSeconds;
      NSMutableArray *tagsArray = [NSMutableArray new];
      for (int i = 0; i < kNumberOfTags; ++i) {
        NSString *val = [id3 tag:[Tags tagNameForIndex:(TagIndex)i]];
        [tagsArray addObject:val == nil? @"": val];
      }
      
      if (self.isCancelled) return;
      
      [_playlistItem createTagsFromArray:tagsArray];
    }
  }
}

@end
