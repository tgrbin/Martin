//
//  TreeNode.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TreeNode : NSObject {
    NSMutableArray *children;
    NSMutableArray *results;
    int searchState;
    NSString *name;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableArray *children;
@property (assign) int searchState;

- (id)initWithName:(NSString*) name;
- (int)nChildren;
- (TreeNode*)getChild:(NSInteger) index;

- (void)addChild:(TreeNode*) child;
- (void)addResult:(TreeNode*) res;
- (void)clearResults;

@end
