//
//  ResourcePaths.h
//  Martin
//
//  Created by Tomislav Grbin on 12/29/12.
//
//

#import <Foundation/Foundation.h>

@interface ResourcePath : NSObject

+ (const char *)libPath;
+ (const char *)rescanPath;
+ (const char *)rescanHelperPath;
+ (const char *)playlistsPath;
+ (const char *)playlistsHelperPath;

@end
