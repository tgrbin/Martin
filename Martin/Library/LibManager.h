//
//  LibManager.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LibManager : NSObject

+ (void)initLibrary;
+ (void)rescanPaths:(NSArray *)paths recursively:(NSArray *)recursively;
+ (void)rescanAll;

@end
