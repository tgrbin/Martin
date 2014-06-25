//
//  PLSPlaylistFile.m
//  Martin
//
//  Created by Tomislav Grbin on 02/03/14.
//
//

#import "PLSPlaylistFile.h"
#import "PlaylistFile+private.h"

@implementation PLSPlaylistFile

- (NSString *)itemFullPathFromLineString:(NSString *)lineString {
  if ([lineString hasPrefix:@"File"]) {
    NSUInteger equalSignPosition = [lineString rangeOfString:@"="].location;
    return [lineString substringFromIndex:equalSignPosition + 1];
  }
  return nil;
}

- (NSString *)stringFromPaths:(NSArray *)paths {
  NSMutableArray *lines = [NSMutableArray new];
  
  [lines addObject:@"[playlist]"];
  [lines addObject:[NSString stringWithFormat:@"numberOfEntries=%ld", paths.count]];
  [lines addObject:@""];
  
  [paths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    [lines addObject:[NSString stringWithFormat:@"File%ld=%@", idx + 1, obj]];
  }];
  
  
  [lines addObject:@""];
  [lines addObject:@"VERSION=2"];
  
  return [lines componentsJoinedByString:@"\n"];
}

@end
