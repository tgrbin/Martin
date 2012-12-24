//
//  LibraryFolders.m
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import "LibraryFolder.h"

@implementation LibraryFolder

+ (NSMutableArray *)libraryFolders {
  static NSMutableArray *arr = nil;

  if (arr == nil) {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Preferences" ofType:@"plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];

    arr = [NSMutableArray new];
    for (id item in [plist objectForKey:@"LibraryFolders"]) {
      [arr addObject:item];
    }
  }

  return arr;
}

+ (void)save {
  NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Preferences" ofType:@"plist"];
  NSDictionary *plist = @{ @"LibraryFolders": [self libraryFolders] };
  [plist writeToFile:plistPath atomically:YES];
}

@end
