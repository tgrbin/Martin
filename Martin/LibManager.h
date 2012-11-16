//
//  LibManager.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TreeNode, Song;

@interface LibManager : NSObject

+ (Song *)songByID:(int)ID;
+ (TreeNode *)getRoot;
+ (void)loadLibrary;
+ (void)search:(NSString *)query;

@end
