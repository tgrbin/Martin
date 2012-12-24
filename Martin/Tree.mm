//
//  Tree.m
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import "Tree.h"
#import "TagsUtils.h"

#import <malloc/malloc.h>
#import <vector>
#import <map>
#import <set>

using namespace std;

struct TreeNode {
  char *name;
  vector<int> children;

  uint8 searchState;
  vector<int> searchMatchingChildren;
  
  int inode;
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
  nodes[0].searchState = 2;
  for (map<int, NSString *>::iterator it = libraryPaths.begin(); it != libraryPaths.end(); ++it) {
    [it->second release];
  }
  libraryPaths.clear();
  songsByInode.clear();
}

+ (int)addChild:(char *)name parent:(int)p_parent song:(int)p_song {
  int node = [self newNode];
  nodes[p_parent].children.push_back(node);
  [self setName:name forNode:node];
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
  return [NSString stringWithCString:nodes[p_node].name encoding:NSUTF8StringEncoding];
}

+ (int)numberOfChildrenForNode:(int)p_node {
  struct TreeNode &node = nodes[p_node];
  
  if (node.searchState == 0) return 0;
  
  if (node.searchState == 1) {
    node.searchMatchingChildren.clear();
    for (auto it = node.children.begin(); it != node.children.end(); ++it) {
      if (nodes[*it].searchState > 0) node.searchMatchingChildren.push_back(*it);
    }
    node.searchState = 4;
  }
  
  if (node.searchState == 2) {
    for (auto it = node.children.begin(); it != node.children.end(); ++it) {
      nodes[*it].searchState = 2;
    }
    node.searchState = 3;
  }
  
  return (int) (node.searchState == 3? node.children.size(): node.searchMatchingChildren.size());
}

+ (int)childAtIndex:(int)i forNode:(int)p_node {
  struct TreeNode &node = nodes[p_node];
  return node.searchState == 3? node.children[i]: node.searchMatchingChildren[i];
}

+ (int)parentOfNode:(int)p_node {
  return nodes[p_node].p_parent;
}

+ (BOOL)isLeaf:(int)p_node {
  return nodes[p_node].children.size() == 0;
}

+ (int)songFromNode:(int)p_node {
  return nodes[p_node].p_song;
}

+ (NSString *)fullPathForSong:(int)p_song {
  return fullPathForNode(songs[p_song].p_treeLeaf);
}

static NSString *fullPathForNode(int p_node) {
  vector<char *> v;
  for (; p_node > 0; p_node = nodes[p_node].p_parent) {
    v.push_back(nodes[p_node].name);
  }
  
  NSMutableString *str = [NSMutableString new];
  for (; v.size(); v.pop_back()) {
    [str appendFormat:@"%@/", [NSString stringWithCString:v.back() encoding:NSUTF8StringEncoding]];
  }
  return str;
}

#pragma mark - rescanning

static set<int> nodesToFindPathsFor;
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
    
    dispatch_sync(dispatch_get_main_queue(), ^{
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
  
  if (poppedCharactersFromQuery && (node.searchState == 2 || node.searchState == 3)) return 2;
  if (appendedCharactersToQuery && node.searchState == 0) return 0;
  
  vector<int> modified;
  for (int i = 0; i < numberOfWords; ++i) {
    if (queryHits[i]) continue;
    
    if (searchInNode(i, node)) {
      queryHits[i] = YES;
      ++numberOfHits;
      modified.push_back(i);
    }
  }
  
  BOOL was2 = (node.searchState == 2);
  node.searchState = 0;
  
  if (numberOfHits == numberOfWords) {
    node.searchState = 2;
  } else {
    for (auto it = node.children.begin(); it != node.children.end(); ++it) {
      if (was2) nodes[*it].searchState = -1;
      if (searchTree(*it)) node.searchState = 1;
    }
  }
  
  for (int i = 0; i < modified.size(); ++i) {
    --numberOfHits;
    queryHits[modified[i]] = NO;
  }
  
  return node.searchState;
}

@end
