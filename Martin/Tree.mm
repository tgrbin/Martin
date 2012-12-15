//
//  Tree.m
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import "Tree.h"
#import "TagsUtils.h"

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

@implementation Tree

static int nodesCounter;
static int songsCounter;
static vector<TreeNode> nodes;
static vector<LibrarySong> songs;
static map<int, NSString *> libraryPaths;
static map<int, int> songsByInode;

+ (void)initialize {
  nodes.resize(128);
  nodes[0].searchState = 2;
  nodes[0].name = @"";
  nodes[0].p_song = -1;
  nodes[0].p_parent = -1;
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
  nodes[0].searchState = 2;
  for (map<int, NSString *>::iterator it = libraryPaths.begin(); it != libraryPaths.end(); ++it) {
    [it->second release];
  }
  libraryPaths.clear();
  songsByInode.clear();
}

+ (int)addChild:(NSString *)name parent:(int)p_parent song:(int)p_song {
  int node = [self newNode];
  nodes[p_parent].children.push_back(node);
  [nodes[node].name release];
  nodes[node].name = [name retain];
  nodes[node].p_parent = p_parent;
  nodes[node].children.clear();
  nodes[node].p_song = p_song;
  if (p_song != -1) songs[p_song].p_treeLeaf = node;
  return node;
}

+ (void)setLibraryPath:(NSString *)p forNode:(int)p_node {
  libraryPaths[p_node] = [p retain];
}

+ (void)addToSongByInodeMap:(int)song inode:(int)inode {
  songsByInode.insert(make_pair(inode, song));
}

+ (int)songByInode:(int)inode {
  map<int, int>::iterator it = songsByInode.find(inode);
  if (it == songsByInode.end()) return -1;
  return it->second;
}

+ (struct LibrarySong *)songDataForP:(int)p_song {
  return &songs[p_song];
}

+ (NSString *)nameForNode:(int)p_node {
  return nodes[p_node].name;
}

+ (int)numberOfChildrenForNode:(int)p_node {
  return (int)nodes[p_node].children.size();
//  if (_searchState == 0) return 0;
//  
//  if (_searchState == 1) {
//    searchResults.clear();
//    for (int i = 0; i < children.size(); ++i) {
//      if (children[i].searchState > 0) searchResults.push_back(children[i]);
//    }
//    _searchState = 4;
//  }
//  
//  if (_searchState == 2) {
//    for (int i = 0; i < children.size(); ++i) {
//      children[i].searchState = 2;
//    }
//    _searchState = 3;
//  }
//  
//  return (int) (_searchState == 3? children.size(): searchResults.size());
}

+ (int)childAtIndex:(int)i forNode:(int)p_node {
  return nodes[p_node].children[i];
//  return _searchState == 3? children[i]: searchResults[i];
}

+ (int)parentOfNode:(int)p_node {
  return nodes[p_node].p_parent;
}

+ (int)songFromNode:(int)p_node {
  return nodes[p_node].p_song;
}

+ (NSString *)fullPathForSong:(int)p_song {
  vector<NSString *> v;
  for (int node = songs[p_song].p_treeLeaf; ; node = nodes[node].p_parent) {
    if (nodes[node].p_parent == 0) { // library folder
      v.push_back(libraryPaths[node]);
      break;
    }
    v.push_back(nodes[node].name);
  }
  
  NSMutableString *str = [NSMutableString stringWithString:v.back()];
  for (v.pop_back(); v.size(); v.pop_back()) {
    [str appendFormat:@"/%@", v.back()];
  }
  return str;
}

@end
