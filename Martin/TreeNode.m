//
//  TreeNode.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TreeNode.h"

@implementation TreeNode

- (id)initWithName:(NSString *)s {
  if( self = [super init] ) {
    _children = [NSMutableArray new];
    results = [NSMutableArray new];
    _name = s;
    _searchState = 0;
  }
  return self;
}

- (id)init {
  return [self initWithName:@"unknown"];
}

- (int)nChildren {    
  if (_searchState == 0) return 0;
  
  if (_searchState == 1) {
    [self clearResults];
    for (TreeNode *c in _children) {
      if (c.searchState > 0) [self addResult:c];
    }
    _searchState = 4;
  }
  
  if (_searchState == 2) {
    for (TreeNode *c in _children) {
      c.searchState = 2;
    }
    _searchState = 3;
  }

  return (int) (_searchState == 3? _children.count: results.count);
}

- (TreeNode *)getChild:(NSInteger) index {
  return _searchState == 3? [_children objectAtIndex:index]: [results objectAtIndex:index];
}

- (void)addChild:(TreeNode *) child {
  [_children addObject:child];
}

- (void)clearResults {
  [results removeAllObjects];
}

- (void)addResult:(TreeNode *) res {
  [results addObject:res];
}

@end
