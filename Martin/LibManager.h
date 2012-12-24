//
//  LibManager.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kLibraryRescanStartedNotification @"LibManagerRescanStarted"
#define kLibraryRescanFinishedNotification @"LibManagerRescanEnded"

@interface LibManager : NSObject

+ (void)initLibrary;
+ (void)rescanPaths:(NSArray *)paths recursively:(NSArray *)recursively;

@end
