//
//  ResourcePaths.m
//  Martin
//
//  Created by Tomislav Grbin on 12/29/12.
//
//

#import "ResourcePath.h"

@implementation ResourcePath

static NSString *basePath;

+ (void)initialize {
  NSString *appSupportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  basePath = [appSupportPath stringByAppendingPathComponent:@"Martin"];

  if ([[NSFileManager defaultManager] createDirectoryAtPath:basePath
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:nil] == NO)
  {
    basePath = [[NSBundle mainBundle] resourcePath];
  }
}

+ (const char *)playlistsPath {
  return resourcePath(@"playlists.pl");
}

+ (const char *)playlistsHelperPath {
  return resourcePath(@"playlists_helper.pl");
}

+ (const char *)libPath {
  return resourcePath(@"martin.lib");
}

+ (const char *)rescanPath {
  return resourcePath(@"martin_rescan.lib");
}

+ (const char *)rescanHelperPath {
  return resourcePath(@"martin_rescan_helper.lib");
}

static const char *resourcePath(NSString *name) {
  return [[basePath stringByAppendingPathComponent:name] UTF8String];
}

@end
