//
//  Tags.m
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import "Tags.h"

@implementation Tags

static int numberOfTags;
static NSString **tagNames;

+ (void)initialize {
  [super initialize];

  NSString *path = [[NSBundle mainBundle] pathForResource:@"LibraryTags" ofType:@"plist"];
  NSArray *arr = [NSArray arrayWithContentsOfFile:path];

  numberOfTags = (int)arr.count;
  tagNames = (NSString **)malloc(numberOfTags * sizeof(NSString*));
  for (int i = 0; i < numberOfTags; ++i) {
    tagNames[i] = [[NSString alloc] initWithString:[arr objectAtIndex:i]];
  }
}

+ (int)numberOfTags {
  return numberOfTags;
}

+ (NSString *)tagNameForIndex:(int)i {
  return tagNames[i];
}

+ (int)indexForTagName:(NSString *)name {
  static NSMutableDictionary *dict = nil;
  if (dict == nil) {
    for (int i = 0; i < numberOfTags; ++i) {
      dict[tagNames[i]] = @(i);
    }
  }

  return [dict[name] intValue];
}

- (id)init {
  if (self = [super init]) {
    tagNames = (NSString **)malloc(numberOfTags * sizeof(NSString*));
    for (int i = 0; i < numberOfTags; ++i) tagNames[i] = nil;
  }
  return self;
}

- (void)dealloc {
  for (int i = 0; i < numberOfTags; ++i) [tagNames[i] release];
  [super dealloc];
}

- (void)setTag:(NSString *)tag forIndex:(int)i {
  [tagNames[i] release];
  tagNames[i] = [tag retain];
}

- (NSString *)tagForIndex:(int)i {
  return tagNames[i];
}

@end