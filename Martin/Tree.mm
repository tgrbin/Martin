//
//  Tree.m
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import "Tree.h"
#import "Tags.h"
#import <vector>
#import <map>

using namespace std;

struct TreeNode {
  NSString *name;
  vector<int> children;

  int searchState;
  vector<int> searchMatchingChildren;
  
  int p_parent;
  int p_song; // != -1 iff node is a leaf
};


struct TreeImpl {
  vector<TreeNode> nodes;
  vector<LibrarySong> songs;
  map<int, NSString *> libraryPaths;
  
  map<int, int> songsByInode;
};

@implementation Tree

+ (Tree *)sharedTree {
  static Tree *tree = nil;
  if (tree == nil) tree = [[Tree alloc] init];
  return tree;
}

- (id)init {
  if (self = [super init]) {
    impl = new TreeImpl;
    impl->nodes.resize(128);
    impl->nodes[0].searchState = 2;
    impl->nodes[0].name = @"";
    impl->nodes[0].p_song = -1;
    impl->nodes[0].p_parent = -1;
  }
  return self;
}

- (int)newNode {
  if (nodesCounter >= impl->nodes.size()) {
    impl->nodes.resize(impl->nodes.size()+256);
  }
  return nodesCounter++;
}

- (int)newSong {
  if (songsCounter >= impl->songs.size()) {
    impl->songs.resize(impl->songs.size()+256);
  }
  if (impl->songs[songsCounter].tags == nil) {
    impl->songs[songsCounter].tags = [Tags new];
  }
  return songsCounter++;
}

- (void)clearTree {
  songsCounter = 0;
  nodesCounter = 1;
  impl->nodes[0].children.clear();
  impl->nodes[0].searchState = 2;
  for (map<int, NSString *>::iterator it = impl->libraryPaths.begin(); it != impl->libraryPaths.end(); ++it) {
    [it->second release];
  }
  impl->libraryPaths.clear();
  impl->songsByInode.clear();
}

- (int)addChild:(NSString *)name parent:(int)p_parent song:(int)p_song {
  int node = [self newNode];
  impl->nodes[p_parent].children.push_back(node);
  [impl->nodes[node].name release];
  impl->nodes[node].name = [name retain];
  impl->nodes[node].p_parent = p_parent;
  impl->nodes[node].children.clear();
  impl->nodes[node].p_song = p_song;
  if (p_song != -1) impl->songs[p_song].p_treeLeaf = node;
  return node;
}

- (void)setLibraryPath:(NSString *)p forNode:(int)p_node {
  impl->libraryPaths[p_node] = [p retain];
}

- (void)addToSongByInodeMap:(int)song inode:(int)inode {
  impl->songsByInode.insert(make_pair(inode, song));
}

- (int)songByInode:(int)inode {
  map<int, int>::iterator it = impl->songsByInode.find(inode);
  if (it == impl->songsByInode.end()) return -1;
  return it->second;
}

- (struct LibrarySong *)songDataForP:(int)p_song {
  return &impl->songs[p_song];
}

- (NSString *)nameForNode:(int)p_node {
  return impl->nodes[p_node].name;
}

- (int)numberOfChildrenForNode:(int)p_node {
  return (int)impl->nodes[p_node].children.size();
//  if (_searchState == 0) return 0;
//  
//  if (_searchState == 1) {
//    impl->searchResults.clear();
//    for (int i = 0; i < impl->children.size(); ++i) {
//      if (impl->children[i].searchState > 0) impl->searchResults.push_back(impl->children[i]);
//    }
//    _searchState = 4;
//  }
//  
//  if (_searchState == 2) {
//    for (int i = 0; i < impl->children.size(); ++i) {
//      impl->children[i].searchState = 2;
//    }
//    _searchState = 3;
//  }
//  
//  return (int) (_searchState == 3? impl->children.size(): impl->searchResults.size());
}

- (int)childAtIndex:(int)i forNode:(int)p_node {
  return impl->nodes[p_node].children[i];
//  return _searchState == 3? impl->children[i]: impl->searchResults[i];
}

- (int)parentOfNode:(int)p_node {
  return impl->nodes[p_node].p_parent;
}

- (int)songFromNode:(int)p_node {
  return impl->nodes[p_node].p_song;
}

- (NSString *)fullPathForSong:(int)p_song {
  vector<NSString *> v;
  for (int node = impl->songs[p_song].p_treeLeaf; ; node = impl->nodes[node].p_parent) {
    if (impl->nodes[node].p_parent == 0) { // library folder
      v.push_back(impl->libraryPaths[node]);
      break;
    }
    v.push_back(impl->nodes[node].name);
  }
  
  NSMutableString *str = [NSMutableString stringWithString:v.back()];
  for (v.pop_back(); v.size(); v.pop_back()) {
    [str appendFormat:@"/%@", v.back()];
  }
  return str;
}

@end
