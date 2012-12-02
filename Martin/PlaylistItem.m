//
//  PlaylistItem.m
//  Martin
//
//  Created by Tomislav Grbin on 11/20/12.
//
//

#import "PlaylistItem.h"
#import "LibManager.h"
#import "Tree.h"

@implementation PlaylistItem

- (id)initWithInode:(int)inode {
  if (self = [super init]) {
    _inode = inode;
    _p_librarySong = [[Tree sharedTree] songByInode:inode];
  }
  return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
  if (self = [super init]) {
    _inode = [dictionary[@"inode"] intValue];
    _filename = dictionary[@"filename"];
    _tags = dictionary[@"tags"];
    _lengthInSeconds = [dictionary[@"length"] intValue];
    if (_inode) _p_librarySong = [[Tree sharedTree] songByInode:_inode];
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
  if (_p_librarySong != -1) return [[Tree sharedTree] fullPathForSong:_p_librarySong];
  return _filename;
}

- (Tags *)tags {
  if (_p_librarySong != -1) return [[Tree sharedTree] songDataForP:_p_librarySong]->tags;
  return _tags;
}

- (int)lengthInSeconds {
  if (_p_librarySong != -1) return [[Tree sharedTree] songDataForP:_p_librarySong]->lengthInSeconds;
  return _lengthInSeconds;
}

@end
