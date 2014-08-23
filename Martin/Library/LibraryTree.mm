//
//  Tree.m
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import "LibraryTree.h"
#import "TagsUtils.h"
#import "LibraryTreeCommon.h"

using namespace std;

@implementation LibraryTree

static int nodesCounter;
static int songsCounter;
vector<LibraryTreeNode> nodes;
vector<LibrarySong> songs;
static tr1::unordered_map<ino_t, int> nodeByInode;

+ (void)initialize {
  nodes.resize(128);
  nodes[0].searchState = kSearchStateWholeNodeMatching;
  nodes[0].p_song = -1;
  nodes[0].p_parent = -1;
  nodes[0].inode = -1;
  nodes[0].name = (char*)malloc(1);
  nodes[0].name[0] = 0;
}

+ (int)newNode {
  if (nodesCounter >= nodes.size()) {
    nodes.resize(nodes.size()+256);
  }
  return nodesCounter++;
}

+ (int)newSong {
  if (songsCounter >= songs.size()) {
    songs.resize(songs.size()+256);
  }
  if (songs[songsCounter].tags == 0) {
    tagsInit(&songs[songsCounter].tags);
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

+ (int)addChild:(char *)name parent:(int)p_parent {
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

+ (void)setName:(char *)name forNode:(int)p_node {
  char **nodeName = &nodes[p_node].name;
  size_t len = strlen(name);
  if (len > 0 && name[len-1] == '\n') name[--len] = 0;
  
  if (*nodeName == NULL) {
    *nodeName = (char *)malloc(len+1);
  } else {
    if (malloc_size(*nodeName) < len+1) *nodeName = (char *)realloc(*nodeName, len+1);
  }
  
  strcpy(*nodeName, name);
}

+ (NSString *)nameForNode:(int)p_node {
  NSString *str = @( nodes[p_node].name );
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
  tr1::unordered_map<ino_t, int>::iterator it = nodeByInode.find(inode);
  return (it == nodeByInode.end())? -1: it->second;
}

+ (char *)cStringPathForSong:(int)p_song {
  return cStringPathForNode(songs[p_song].p_treeLeaf);
}

+ (NSString *)pathForSong:(int)p_song {
  return fullPathForNode(songs[p_song].p_treeLeaf);
}

static char *cStringPathForNode(int p_node) {
  static char buff[1<<16];
  
  vector<int> path;
  for (; p_node > 0; p_node = nodes[p_node].p_parent) path.push_back(p_node);
  reverse(path.begin(), path.end());
  
  size_t n = path.size();
  char *name, *pos = buff;
  for (int i = 0; i < n; ++i) {
    name = nodes[path[i]].name;
    strcpy(pos, name);
    pos += strlen(name);
    *pos++ = '/';
  }
  *--pos = 0;
  
  return buff;
}

static NSString *fullPathForNode(int p_node) {
  return @( cStringPathForNode(p_node) );
}

#pragma mark - rescanning

static tr1::unordered_set<int> nodesToFindPathsFor;
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
