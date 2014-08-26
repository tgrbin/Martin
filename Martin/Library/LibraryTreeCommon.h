//
//  LibraryTreeCommon.h
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import "LibrarySong.h"
#import "LibraryTreeNode.h"

#import <malloc/malloc.h>
#import <vector>
#import <unordered_map>
#import <unordered_set>

using namespace std;

extern vector<LibraryTreeNode> nodes;
extern vector<LibrarySong> songs;

typedef enum {
  kSearchStateNotMatching = 0,
  kSearchStateSomeChildrenMatching = 1,
  kSearchStateWholeNodeMatching = 2,
  
  // during traversal, this means that correct searchState values were already propagated to node's children
  kSearchStateWholeNodePropagated = 3,
  kSearchStateSomeChildrenPropagated = 4
} SearchState;
