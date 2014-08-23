//
//  LibraryTreeOutlineViewState.m
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import "LibraryTreeOutlineViewState.h"
#import "LibraryTreeCommon.h"

@implementation LibraryTreeOutlineViewState

#pragma mark - inodes and levels, used for storing tree state between rescans

static tr1::unordered_set<int> restore_nodes;
static tr1::unordered_set<uint64> restore_inodesAndLevels;
static BOOL restoringNodes;

+ (void)storeInodesAndLevelsForNodes:(NSSet *)nodes {
  for (NSNumber *n in nodes) restore_nodes.insert(n.intValue);
  
  restoringNodes = NO;
  findInodesForNodes(0, 0);

  restore_nodes.clear();
}

+ (void)restoreNodesForStoredInodesAndLevelsToSet:(NSMutableSet *)set {
  restoringNodes = YES;
  findInodesForNodes(0, 0);
  
  [set removeAllObjects];
  for (auto it = restore_nodes.begin(); it != restore_nodes.end(); ++it) [set addObject:@(*it)];
  
  restore_nodes.clear();
  restore_inodesAndLevels.clear();
}

static void findInodesForNodes(int p_node, int level) {
  struct LibraryTreeNode *node = &nodes[p_node];
  
  uint64 val = node->inode * 100 + level;
  if (restoringNodes == NO) {
    if (restore_nodes.count(p_node)) restore_inodesAndLevels.insert(val);
  } else {
    if (restore_inodesAndLevels.count(val)) restore_nodes.insert(p_node);
  }
  
  for (auto child = node->children.begin(); child != node->children.end(); ++child) {
    findInodesForNodes(*child, level+1);
  }
}

@end
