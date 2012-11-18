//
//  LibManager.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kLibManagerRescanedLibraryNotification @"LibManagerRescanedLibraryNotification"

@class TreeNode, Song;
struct LibManagerImpl;

@interface LibManager : NSObject {
  TreeNode *root;
  struct LibManagerImpl *impl;
}

+ (LibManager *)sharedManager;

- (void)loadLibrary;
- (void)rescanLibraryWithProgressBlock:(void (^)(int))progressBlock;

- (TreeNode *)treeRoot;
- (Song *)songByID:(int)ID;

- (void)performSearch:(NSString *)query;

@end
