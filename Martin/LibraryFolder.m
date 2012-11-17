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
      [arr addObject:[[LibraryFolder alloc] initWithDictionary:item]];
    }
  }
  
  return arr;
}

+ (void)save {
  NSMutableArray *arr = [NSMutableArray new];
  for (LibraryFolder *lf in [self libraryFolders]) {
    NSDictionary *dict = @{
      @"path": lf.folderPath,
      @"treeDisplayName": lf.treeDisplayName
    };
    [arr addObject:dict];
  }
  
  NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Preferences" ofType:@"plist"];
  NSDictionary *plist = @{ @"LibraryFolders": arr };
  [plist writeToFile:plistPath atomically:YES];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
  if (self = [super init]) {
    _folderPath = [dictionary objectForKey:@"path"];
    _treeDisplayName = [dictionary objectForKey:@"treeDisplayName"];
  }
  return self;
}

@end
