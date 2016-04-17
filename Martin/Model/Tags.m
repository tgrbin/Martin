//
//  Tags.m
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import "Tags.h"

@interface Tags()
@property (nonatomic, strong) NSArray *values;
@end

@implementation Tags

+ (NSString *)tagNameForIndex:(TagIndex)i {
  static NSString *arr[kNumberOfTags] = { @"track number", @"artist", @"album", @"title", @"genre", @"year" };
  return arr[i];
}

+ (TagIndex)indexFromTagName:(NSString *)str {
  static NSMutableDictionary *dict = nil;
  if (dict == nil) {
    dict = [NSMutableDictionary new];
    for (int i = 0; i < kNumberOfTags; ++i) {
      dict[[self tagNameForIndex:i]] = @(i);
    }
  }
  return [dict[str] intValue];
}

+ (Tags *)createTagsFromCTags:(char **)tags {
  Tags *t = [Tags new];
  NSMutableArray *arr = [NSMutableArray new];
  for (int i = 0; i < kNumberOfTags; ++i) {
    [arr addObject:[[NSString alloc] initWithCString:tags[i] encoding:NSUTF8StringEncoding]];
  }
  t.values = arr;
  return t;
}

+ (Tags *)createTagsFromArray:(NSArray *)tags {
  Tags *t = [Tags new];
  t.values = tags;
  return t;
}

- (NSString *)tagValueForIndex:(TagIndex)i {
  return self.values[i];
}

@end
