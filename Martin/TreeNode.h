//
//  TreeNode.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TreeNode : NSObject {
  NSMutableArray *results;
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray *children;
@property (assign) int searchState;

- (id)initWithName:(NSString *) name;
- (int)nChildren;
- (TreeNode *)getChild:(NSInteger) index;

- (void)addChild:(TreeNode *) child;
- (void)addResult:(TreeNode *) res;
- (void)clearResults;

@end
