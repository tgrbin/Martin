//
//  LibManager.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//

#import <Foundation/Foundation.h>

@interface LibManager : NSObject

+ (void)initLibrary;

+ (void)rescanAll;

+ (void)rescanPaths:(NSArray *)paths recursively:(NSArray *)recursively;

@end
