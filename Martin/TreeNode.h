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

  int inode;
  int p_parent;
  int p_song; // != -1 iff node is a leaf

  uint8 searchState;
  vector<int> searchMatchingChildren;
};
