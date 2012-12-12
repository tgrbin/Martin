//
//  Tags.m
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import <malloc/malloc.h>
#import "Tags.h"
#import "TagsUtils.h"

@interface Tags()
@property (nonatomic, unsafe_unretained) NSString **values;
@end

@implementation Tags

+ (Tags *)createTagsFromCTags:(char **)tags {
  Tags *t = [[Tags alloc] init];
  t.values = (NSString **)malloc(kNumberOfTags * sizeof(NSString*));
  for (int i = 0; i < kNumberOfTags; ++i) {
    t.values[i] = [[NSString alloc] initWithCString:tags[i] encoding:NSUTF8StringEncoding];
  }
  return t;
}

- (NSString *)tagValueForIndex:(int)i {
  return self.values[i];
}

- (void)dealloc {
  for (int i = 0; i < kNumberOfTags; ++i) [self.values[i] release];
  free(self.values);
  [super dealloc];
}

@end
