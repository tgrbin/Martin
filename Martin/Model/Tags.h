//
//  Tags.h
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import <Foundation/Foundation.h>

#define kNumberOfTags 6

// "track number", "artist", "album", "title", "genre", "year"

typedef enum {
  kTagIndexTrackNumber,
  kTagIndexArtist,
  kTagIndexAlbum,
  kTagIndexTitle,
  kTagIndexGenre,
  kTagIndexYear
} TagIndex;

@interface Tags : NSObject

+ (NSString *)tagNameForIndex:(TagIndex)i;
+ (TagIndex)indexFromTagName:(NSString *)str;

+ (Tags *)createTagsFromArray:(NSArray *)tags;

- (NSString *)tagValueForIndex:(TagIndex)i;

@end
