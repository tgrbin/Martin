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

@end
