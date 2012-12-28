//
//  LibraryFolders.m
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import "LibraryFolder.h"
#import "DefaultsManager.h"

@implementation LibraryFolder

+ (NSMutableArray *)libraryFolders {
  static NSMutableArray *arr = nil;
  if (arr == nil) {
    arr = [NSMutableArray arrayWithArray:[DefaultsManager objectForKey:kDefaultsKeyLibraryFolders]];
  }
  return arr;
}

+ (void)save {
  [DefaultsManager setObject:[self libraryFolders] forKey:kDefaultsKeyLibraryFolders];
}

@end
