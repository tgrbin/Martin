//
//  Tree.m
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import "Tree.h"
#import "TagsUtils.h"
#import "TreeNode.h"

#import <malloc/malloc.h>
#import <vector>
#import <tr1/unordered_map>
#import <tr1/unordered_set>

NSString * const kLibrarySearchFinishedNotification = @"LibManagerSearchFinished";

using namespace std;

typedef enum {
  kSearchStateNotMatching = 0,
  kSearchStateSomeChildrenMatching = 1,
  kSearchStateWholeNodeMatching = 2,
  
  // during traversal, this means that correct searchState values were already propagated to node's children
  kSearchStateWholeNodePropagated = 3,
  kSearchStateSomeChildrenPropagated = 4
} SearchState;

@implementation Tree

static int nodesCounter;
static int songsCounter;
static vector<TreeNode> nodes;
static vector<LibrarySong> songs;
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

+ (struct TreeNode *)treeNodeDataForP:(int)p_node {
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
  struct TreeNode &node = nodes[p_node];
  
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
  struct TreeNode &node = nodes[p_node];
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
  struct TreeNode *node = &nodes[p_node];
  
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

#pragma mark - search

static const int kBuffSize = 256; // maximum number of characters in a query
static NSLock *searchLock;
static BOOL appendedCharactersToQuery;
static BOOL poppedCharactersFromQuery;
static NSString *previousSearchQuery;
static NSString *pendingSearchQuery;
static BOOL nowSearching;

static int numberOfWords;
static char searchWords[kBuffSize][kBuffSize];
static size_t wordLen[kBuffSize];
static int kmpLookup[kBuffSize][kBuffSize];
static BOOL queryHits[kBuffSize];
static int numberOfHits;

+ (void)resetSearchState {
  @synchronized(searchLock) {
    [previousSearchQuery release];
    previousSearchQuery = @"";
  }
}

+ (void)performSearch:(NSString *)query {
  if (searchLock == nil) {
    searchLock = [NSLock new];
    previousSearchQuery = @"";
  }

  if (query.length > kBuffSize/2) return;
  
  @synchronized(searchLock) {
    if (nowSearching == YES) {
      [pendingSearchQuery release];
      pendingSearchQuery = [query retain];
      return;
    }
    nowSearching = YES;
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *currentQuery = [query copy];
    
    for (;;) {
      initKMPStructures(currentQuery);

      appendedCharactersToQuery = [currentQuery hasPrefix:previousSearchQuery];
      poppedCharactersFromQuery = [previousSearchQuery hasPrefix:currentQuery];

      searchTree(0);
      
      [previousSearchQuery release];
      previousSearchQuery = [currentQuery copy];
      
      @synchronized(searchLock) {
        if (pendingSearchQuery) {
          [currentQuery release];
          currentQuery = [pendingSearchQuery copy];
          [pendingSearchQuery release];
          pendingSearchQuery = nil;
        } else {
          [currentQuery release];
          break;
        }
      }
    }
    
    @synchronized(searchLock) {
      nowSearching = NO;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kLibrarySearchFinishedNotification object:nil];
    });
  });
}

static void initKMPStructures(NSString *query) {
  numberOfWords = 0;
  
  for (NSString *word in [query componentsSeparatedByString:@" "]) {
    if (word.length == 0) continue;
    
    char *w = searchWords[numberOfWords];
    int *t = kmpLookup[numberOfWords];
    
    [word getCString:w maxLength:kBuffSize encoding:NSUTF8StringEncoding];
    
    size_t len = strlen(w);
    wordLen[numberOfWords++] = len;
    
    int i = 0;
    int j = t[0] = -1;
    while (i < len) {
      while (j > -1 && toupper(w[i]) != toupper(w[j])) j = t[j];
      ++i;
      ++j;
      if (toupper(w[i]) == toupper(w[j])) t[i] = t[j];
      else t[i] = j;
    }
  }
}

static BOOL kmpSearch(int wordIndex, const char *str) {
  char *w = searchWords[wordIndex];
  int *t = kmpLookup[wordIndex];
  size_t len = wordLen[wordIndex];
  
  size_t strLen = strlen(str);
  int i = 0, j = 0;
  while (j < strLen) {
    while (i > -1 && toupper(w[i]) != toupper(str[j])) i = t[i];
    ++i;
    ++j;
    if (i >= len) return YES;
  }
  return NO;
}

static BOOL searchInNode(int wordIndex, const struct TreeNode &node) {
  if (kmpSearch(wordIndex, node.name)) return YES;
  
  if (node.p_song == -1) return NO;
  
  struct LibrarySong &song = songs[node.p_song];
  for (int i = 0; i < kNumberOfTags; ++i) {
    if (kmpSearch(wordIndex, song.tags[i]) == YES) return YES;
  }

  return NO;
}

static int searchTree(int p_node) {
  struct TreeNode &node = nodes[p_node];
  
  BOOL wholeNodeMatching = (node.searchState == kSearchStateWholeNodeMatching || node.searchState == kSearchStateWholeNodePropagated);
  
  if (poppedCharactersFromQuery && wholeNodeMatching) return 1;
  if (appendedCharactersToQuery && node.searchState == kSearchStateNotMatching) return 0;
  
  vector<int> modified;
  for (int i = 0; i < numberOfWords; ++i) {
    if (queryHits[i]) continue;
    
    if (searchInNode(i, node)) {
      queryHits[i] = YES;
      ++numberOfHits;
      modified.push_back(i);
    }
  }
  
  if (numberOfHits == numberOfWords) {
    node.searchState = kSearchStateWholeNodeMatching;
  } else {
    node.searchState = kSearchStateNotMatching;
  
    for (auto it = node.children.begin(); it != node.children.end(); ++it) {
      if (wholeNodeMatching) {
        nodes[*it].searchState = kSearchStateWholeNodeMatching;
      }
      if (searchTree(*it)) {
        node.searchState = kSearchStateSomeChildrenMatching;
      }
    }
  }
  
  for (int i = 0; i < modified.size(); ++i) {
    --numberOfHits;
    queryHits[modified[i]] = NO;
  }
  
  return node.searchState > 0? 1: 0;
}

@end
