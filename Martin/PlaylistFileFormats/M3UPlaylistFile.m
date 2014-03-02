//
//  M3UPlaylistFile.m
//  Martin
//
//  Created by Tomislav Grbin on 02/03/14.
//
//

#import "M3UPlaylistFile.h"
#import "PlaylistFile+private.h"

@implementation M3UPlaylistFile

- (NSString *)itemFullPathFromLineString:(NSString *)lineString {
  if ([lineString hasPrefix:@"#"]) return nil;
  return lineString;
}

@end
