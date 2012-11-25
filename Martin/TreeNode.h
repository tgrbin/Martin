//
//  TreeNode.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

struct TreeNodeImpl;

@interface TreeNode : NSObject {
  struct TreeNodeImpl *impl;
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) int searchState;

- (id)initWithName:(NSString *)name;
- (int)nChildren;
- (TreeNode *)getChild:(NSInteger)index;

- (void)addChild:(TreeNode *)child;

// just libmanager uses this while searching
- (int)childrenVectorCount;
- (TreeNode *)childrenVectorAtIndex:(int)i;

@end
