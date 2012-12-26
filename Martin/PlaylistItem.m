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
#import "Tags.h"

@implementation PlaylistItem

- (id)initWithLibrarySong:(int)p_song {
  if (self = [super init]) {
    _p_librarySong = p_song;
  }
  return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
  if (self = [super init]) {
    _inode = [dictionary[@"inode"] intValue];
    _filename = dictionary[@"filename"];
    _lengthInSeconds = [dictionary[@"length"] intValue];

    _p_librarySong = _inode? [Tree songByInode:_inode]: -1;

    if (_p_librarySong == -1 && [dictionary objectForKey:@"tags"] != nil) {
      tags = [Tags createTagsFromArray:dictionary[@"tags"]];
    }
  }
  return self;
}

- (NSDictionary *)dictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  dict[@"inode"] = [NSString stringWithFormat:@"%d", _inode];
  dict[@"length"] = [NSString stringWithFormat:@"%d", self.lengthInSeconds];
  if (self.filename) dict[@"filename"] = self.filename;

  NSMutableArray *tagsArr = [NSMutableArray array];
  for (int i = 0; i < kNumberOfTags; ++i) [tagsArr addObject:[self tagValueForIndex:i]];
  dict[@"tags"] = tagsArr;

  return dict;
}

- (NSString *)filename {
  if (_p_librarySong != -1) return [Tree fullPathForSong:_p_librarySong];
  return _filename;
}

- (int)lengthInSeconds {
  if (_p_librarySong != -1) return [Tree songDataForP:_p_librarySong]->lengthInSeconds;
  return _lengthInSeconds;
}

- (NSString *)tagValueForIndex:(int)i {
  if (_p_librarySong != -1) {
    char **t = [Tree songDataForP:_p_librarySong]->tags;
    return [NSString stringWithCString:t[i] encoding:NSUTF8StringEncoding];
  } else {
    return [tags tagValueForIndex:i];
  }
}

- (NSString *)prettyName {
  return [NSString stringWithFormat:@"%@ - %@ - %@", [self tagValueForIndex:2], [self tagValueForIndex:1], [self tagValueForIndex:3]];
}

@end
