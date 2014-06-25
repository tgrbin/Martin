//
//  PlaylistFile+private.h
//  Martin
//
//  Created by Tomislav Grbin on 02/03/14.
//
//

#import "PlaylistFile.h"

@interface PlaylistFile ()

@property (nonatomic, strong) NSString *filename;

// this method returns full path to a playlist item,
// or nil if that line doesn't contain a playlist item
- (NSString *)itemFullPathFromLineString:(NSString *)lineString;

// encode path list to string that can be saved directly to a file
- (NSString *)stringFromPaths:(NSArray *)paths;

@end
