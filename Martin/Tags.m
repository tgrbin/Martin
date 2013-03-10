//
//  Tags.m
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import "Tags.h"

static const char *tagNames[] = { "track number", "artist", "album", "title", "genre" };

@interface Tags()
@property (nonatomic, unsafe_unretained) NSString **values;
@end

@implementation Tags

+ (NSString *)tagNameForIndex:(TagIndex)i {
  static NSString *arr[kNumberOfTags];
  if (arr[0] == nil) {
    for (int i = 0; i < kNumberOfTags; ++i) arr[i] = [[NSString alloc] initWithCString:tagNames[i] encoding:NSUTF8StringEncoding];
  }
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
  t.values = (NSString **)malloc(kNumberOfTags * sizeof(NSString*));
  for (int i = 0; i < kNumberOfTags; ++i) {
    t.values[i] = [[NSString alloc] initWithCString:tags[i] encoding:NSUTF8StringEncoding];
  }
  return t;
}

+ (Tags *)createTagsFromArray:(NSArray *)tags {
  Tags *t = [Tags new];
  t.values = (NSString **)malloc(kNumberOfTags * sizeof(NSString*));
  for (int i = 0; i < kNumberOfTags; ++i) {
    t.values[i] = [tags[i] retain];
  }
  return t;
}

- (NSString *)tagValueForIndex:(TagIndex)i {
  return self.values[i];
}

- (void)dealloc {
  for (int i = 0; i < kNumberOfTags; ++i) [self.values[i] release];
  free(self.values);
  [super dealloc];
}

@end
