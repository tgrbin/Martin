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
    triedToGetSong = NO;
  }
  return self;
}

- (NSDictionary *)dictionary {
  return @{
    @"inode": [NSString stringWithFormat:@"%d", _inode],
    @"filename": _filename,
    @"tags": _tags,
    @"length": [NSString stringWithFormat:@"%d", _lengthInSeconds]
  };
}

- (Song *)song {
  if (_inode == 0) return nil;
  if (triedToGetSong) return _song;
  triedToGetSong = YES;
  return _song = [[LibManager sharedManager] songByID:_inode];
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
