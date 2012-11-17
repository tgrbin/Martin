//
//  LibraryTags.m
//  Martin
//
//  Created by Tomislav Grbin on 11/17/12.
//
//

#import "LibraryTags.h"

@implementation LibraryTags

+ (NSArray *)tags {
  static NSMutableArray *arr = nil;
  
  if (arr == nil) {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"LibraryTags" ofType:@"plist"];
    arr = [NSArray arrayWithContentsOfFile:path];
  }
  
  return arr;
}

@end
