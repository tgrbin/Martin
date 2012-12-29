//
//  ResourcePaths.m
//  Martin
//
//  Created by Tomislav Grbin on 12/29/12.
//
//

#import "ResourcePath.h"

@implementation ResourcePath

+ (const char *)playlistsPath {
  static NSString *path = nil;
  if (path == nil) path = resourcePath(@"playlists.pl");
  return [path UTF8String];
}

+ (const char *)playlistsHelperPath {
  static NSString *path = nil;
  if (path == nil) path = resourcePath(@"playlists_helper.pl");
  return [path UTF8String];
}

+ (const char *)libPath {
  static NSString *path = nil;
  if (path == nil) path = resourcePath(@"martin.lib");
  return [path UTF8String];
}

+ (const char *)rescanPath {
  static NSString *path = nil;
  if (path == nil) path = resourcePath(@"martin_rescan.lib");
  return [path UTF8String];
}

+ (const char *)rescanHelperPath {
  static NSString *path = nil;
  if (path == nil) path = resourcePath(@"martin_rescan_helper.lib");
  return [path UTF8String];
}

static NSString *resourcePath(NSString *name) {
  return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:name];
}

@end
