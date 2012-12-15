//
//  LibManager.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kLibManagerRescanedLibraryNotification @"LibManagerRescanedLibraryNotification"
#define kLibManagerFinishedSearchNotification @"LibManagerFinishedSearch"

struct LibManagerImpl;

@interface LibManager : NSObject {
  NSString *previousSearchQuery;
  BOOL appendedCharactersToQuery;
  BOOL poppedCharactersFromQuery;
}

+ (LibManager *)sharedManager;

- (void)rescanLibraryWithProgressBlock:(void (^)(int))progressBlock;
- (void)rescanFolder:(const char *)folderPath withBlock:(void (^)(int))block;

- (void)performSearch:(NSString *)query;

@end
