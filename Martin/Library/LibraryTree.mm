//
//  Tree.m
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import "LibraryTree.h"
#import "LibraryTreeCommon.h"

using namespace std;

@implementation LibraryTree

static int nodesCounter;
static int songsCounter;
vector<LibraryTreeNode> nodes;
vector<LibrarySong> songs;
static unordered_map<ino_t, int> nodeByInode;

+ (void)initialize {
  nodes.resize(128);
  nodes[0].searchState = kSearchStateWholeNodeMatching;
  nodes[0].p_song = -1;
  nodes[0].p_parent = -1;
  nodes[0].inode = -1;
  nodes[0].name = @"";
}

+ (int)newNode {
  if (nodesCounter >= nodes.size()) {
    nodes.resize(nodes.size() + 256);
  }
  return nodesCounter++;
}

+ (int)newSong {
  if (songsCounter >= songs.size()) {
    songs.resize(songs.size() + 256);
  }
  return songsCounter++;
}

+ (void)clearTree {
  songsCounter = 0;
  nodesCounter = 1;
  nodes[0].children.clear();
  nodes[0].searchState = kSearchStateWholeNodeMatching;
  nodeByInode.clear();
}

+ (int)addChild:(NSString *)name parent:(int)p_parent {
  int node = [self newNode];
  nodes[p_parent].children.push_back(node);
  [self setName:name forNode:node];
  nodes[node].p_parent = p_parent;
  nodes[node].children.clear();
  nodes[node].p_song = -1;
  return node;
}

+ (void)addToNodeByInodeMap:(int)node {
  nodeByInode.insert(make_pair(nodes[node].inode, node));
}

+ (struct LibrarySong *)songDataForP:(int)p_song {
  return &songs[p_song];
}

+ (struct LibraryTreeNode *)treeNodeDataForP:(int)p_node {
  return &nodes[p_node];
}

+ (void)setName:(NSString *)name forNode:(int)p_node {
  if ([name characterAtIndex:name.length - 1] == '\n') {
    name = [name substringToIndex:name.length - 1];
  }
  nodes[p_node].name = name;
}

+ (NSString *)nameForNode:(int)p_node {
  NSString *str = nodes[p_node].name;
  if (nodes[p_node].p_parent == 0) return [str lastPathComponent];
  return str;
}

+ (int)numberOfChildrenForNode:(int)p_node {
  struct LibraryTreeNode &node = nodes[p_node];
  
  if (node.searchState == kSearchStateNotMatching) return 0;
  
  if (node.searchState == kSearchStateSomeChildrenMatching) {
    node.searchMatchingChildren.clear();
    for (auto it = node.children.begin(); it != node.children.end(); ++it) {
      if (nodes[*it].searchState > 0) node.searchMatchingChildren.push_back(*it);
    }
    node.searchState = kSearchStateSomeChildrenPropagated;
  }
  
  if (node.searchState == kSearchStateWholeNodeMatching) {
    for (auto it = node.children.begin(); it != node.children.end(); ++it) {
      nodes[*it].searchState = kSearchStateWholeNodeMatching;
    }
    node.searchState = kSearchStateWholeNodePropagated;
  }
  
  return (int) (node.searchState == kSearchStateWholeNodePropagated? node.children.size(): node.searchMatchingChildren.size());
}

+ (int)childAtIndex:(int)i forNode:(int)p_node {
  struct LibraryTreeNode &node = nodes[p_node];
  return node.searchState == kSearchStateWholeNodePropagated? node.children[i]: node.searchMatchingChildren[i];
}

+ (int)parentOfNode:(int)p_node {
  return nodes[p_node].p_parent;
}

+ (BOOL)isLeaf:(int)p_node {
  return nodes[p_node].p_song != -1;
}

+ (int)songFromNode:(int)p_node {
  return nodes[p_node].p_song;
}

+ (ino_t)inodeForSong:(int)p_song {
  return nodes[songs[p_song].p_treeLeaf].inode;
}

+ (int)songByInode:(ino_t)inode {
  int node = [self nodeByInode:inode];
  return node == -1? -1: nodes[node].p_song;
}

+ (int)nodeByInode:(ino_t)inode {
  unordered_map<ino_t, int>::iterator it = nodeByInode.find(inode);
  return (it == nodeByInode.end())? -1: it->second;
}

+ (NSString *)pathForSong:(int)p_song {
  return fullPathForNode(songs[p_song].p_treeLeaf);
}

static NSString *fullPathForNode(int p_node) {
  vector<int> path;
  for (; p_node > 0; p_node = nodes[p_node].p_parent) path.push_back(p_node);
  reverse(path.begin(), path.end());

  NSMutableString *str = [NSMutableString new];
  for (int node : path) {
    if (str.length > 0) {
      [str appendString:@"/"];
    }
    [str appendString:nodes[node].name];
  }
  
  return str;
}

#pragma mark - rescanning

static unordered_set<int> nodesToFindPathsFor;
static NSMutableArray *pathsForNodes;

+ (NSArray *)pathsForNodes:(NSArray *)nodes {
  nodesToFindPathsFor.clear();
  for (NSNumber *num in nodes) nodesToFindPathsFor.insert(num.intValue);

  if (pathsForNodes == nil) pathsForNodes = [NSMutableArray new];
  [pathsForNodes removeAllObjects];
  
  findPathsForNodes(0);
  return pathsForNodes;
}

static void findPathsForNodes(int p_node) {
  if (nodesToFindPathsFor.count(p_node)) {
    [pathsForNodes addObject:fullPathForNode(p_node)];
  } else {
    for (auto child = nodes[p_node].children.begin(); child != nodes[p_node].children.end(); ++child) {
      findPathsForNodes(*child);
    }
  }
}

@end
