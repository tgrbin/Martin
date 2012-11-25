//
//  TreeNode.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TreeNode.h"
#import <vector>

using namespace std;

struct TreeNodeImpl {
  vector<TreeNode *> children;
  vector<TreeNode *> searchResults;
};

@implementation TreeNode

- (id)initWithName:(NSString *)s {
  if (self = [super init]) {
    impl = new TreeNodeImpl();
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
    impl->searchResults.clear();
    for (int i = 0; i < impl->children.size(); ++i) {
      if (impl->children[i].searchState > 0) impl->searchResults.push_back(impl->children[i]);
    }
    _searchState = 4;
  }
  
  if (_searchState == 2) {
    for (int i = 0; i < impl->children.size(); ++i) {
      impl->children[i].searchState = 2;
    }
    _searchState = 3;
  }

  return (int) (_searchState == 3? impl->children.size(): impl->searchResults.size());
}

- (TreeNode *)getChild:(NSInteger)i {
  return _searchState == 3? impl->children[i]: impl->searchResults[i];
}

- (void)addChild:(TreeNode *)child {
  impl->children.push_back(child);
}

- (int)childrenVectorCount {
  return (int)impl->children.size();
}

- (TreeNode *)childrenVectorAtIndex:(int)i {
  return impl->children[i];
}

@end
