//
//  PlaylistItem.m
//  Martin
//
//  Created by Tomislav Grbin on 11/20/12.
//
//

#import "PlaylistItem.h"
#import "LibManager.h"
#import "Song.h"

@implementation PlaylistItem

- (id)initWithDictionary:(NSDictionary *)dictionary {
  if (self = [super init]) {
    _inode = [dictionary[@"inode"] intValue];
    _filename = dictionary[@"filename"];
    _tags = dictionary[@"tags"];
    _lengthInSeconds = [dictionary[@"length"] intValue];
    if (_inode) _song = [[LibManager sharedManager] songByID:_inode];
  }
  return self;
}

- (NSDictionary *)dictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  dict[@"inode"] = [NSString stringWithFormat:@"%d", _inode];
  dict[@"length"] = [NSString stringWithFormat:@"%d", self.lengthInSeconds];
  if (self.filename) dict[@"filename"] = self.filename;
  if (self.tags) dict[@"tags"] = self.tags;
  return dict;
}

- (NSString *)filename {
  if (self.song) return self.song.filename;
  return _filename;
}

- (NSDictionary *)tags {
  if (self.song) return self.song.tagsDictionary;
  return _tags;
}

- (int)lengthInSeconds {
  if (self.song) return self.song.lengthInSeconds;
  return _lengthInSeconds;
}

@end
