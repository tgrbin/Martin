//
//  TreeNode.h
//  Martin
//
//  Created by Tomislav Grbin on 12/24/12.
//
//

#import <vector>

using namespace std;

struct TreeNode {
  char *name;
  vector<int> children;

  ino_t inode;
  int p_parent;
  int p_song;

  uint8 searchState;
  vector<int> searchMatchingChildren;
};
