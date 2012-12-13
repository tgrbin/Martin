//
//  Playlist.m
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Playlist.h"
#import "LibManager.h"
#import "PlaylistItem.h"
#import "PlaylistManager.h"
#import "FilePlayer.h"
#import "Tree.h"
#import "Tags.h"
#import "TagsUtils.h"

#import <algorithm>
#import <numeric>
#import <vector>
#import <set>

using namespace std;

@implementation Playlist

struct PlaylistImpl {
  vector<PlaylistItem *> playlistItems;

  // these vectors hold indexes within playlistItems vector
  vector<int> playlist;
  vector<int> shuffled;
};

#pragma mark - init

- (id)initWithName:(NSString *)n playlistItems:(NSArray *)s {
  if (self = [super init]) {
    _name = n;
    impl = new PlaylistImpl;

    currentItem = -1;
    
    for (id item in s) {
      impl->playlistItems.push_back(item);
    }
    
    impl->playlist.resize(s.count);
    iota(impl->playlist.begin(), impl->playlist.end(), 0);
    
    impl->shuffled = impl->playlist;
    srand((unsigned int) time(0));
    random_shuffle(impl->shuffled.begin(), impl->shuffled.end());
  }
  return self;
}

- (void)dealloc {
  delete impl;
}

- (id)initWithTreeNodes:(NSArray *)arr {
  if (self = [self init]) {
    [self guessNameAndAddItems:arr];
  }
  return self;
}

- (id)initWithPlaylistItems:(NSArray *)arr {
  if (self = [self initWithName:@"" playlistItems:arr]) {
    [self guessNameAndAddItems:arr];
  }
  return self;
}

- (id)init {
  return [self initWithName:@"new playlist" playlistItems:@[]];
}

- (void)guessNameAndAddItems:(NSArray *)arr { // arr contains treenodes or playlistitems
  NSMutableDictionary *foldersAndCounts = [NSMutableDictionary new];
  int currCount = 0;
  
  for (id item in arr) {
    NSString *folderName;
    if ([item isKindOfClass:[PlaylistItem class]]) {
      folderName = [[((PlaylistItem *)item).filename stringByDeletingLastPathComponent] lastPathComponent];
    } else {
      int node = [item intValue];
      int song = [[Tree sharedTree] songFromNode:node];
      
      if (song != -1) node = [[Tree sharedTree] parentOfNode:node];
        
      folderName = [[Tree sharedTree] nameForNode:node];
      
      [self addTreeNodes:@[item] atPos:currCount];
    }
    
    int oldVal = [foldersAndCounts[folderName] intValue];
    foldersAndCounts[folderName] = @(oldVal + self.numberOfItems - currCount);
    currCount = self.numberOfItems;
  }
  
  NSMutableArray *ordered = [NSMutableArray new];
  for (id item in foldersAndCounts) [ordered addObject:@[item, foldersAndCounts[item]]];
  [ordered sortUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) {return [a[1] compare:b[1]];}];
  
  NSMutableString *suggestedName = [NSMutableString stringWithFormat:@"%@", ordered[0][0]];
  for (int i = 1; i < 3; ++i) {
    if (i == ordered.count) break;
    [suggestedName appendFormat:@", %@", ordered[i][0]];
  }
  _name = suggestedName;
}

#pragma mark - manage playlist

- (void)addPlaylistItems:(NSArray *)arr {
  [self resetCurrentItemIfStopped];
  [self addPlaylistItemsOrTreeNodes:arr atPos:self.numberOfItems];
}

- (void)addTreeNodes:(NSArray *)treeNodes atPos:(int)pos {
  [self resetCurrentItemIfStopped];
  [self addPlaylistItemsOrTreeNodes:treeNodes atPos:pos];
}

- (void)addPlaylistItemsOrTreeNodes:(NSArray *)arr atPos:(int)pos {
  [self resetCurrentItemIfStopped];
  
  int oldSize = (int)impl->playlistItems.size();
  for (id item in arr) {
    if ([item isKindOfClass:[PlaylistItem class]]) {
      impl->playlistItems.push_back(item);
    } else {
      [self traverseNodeAndAddItems:[item intValue]];
    }
  }
  int newSize = (int)impl->playlistItems.size();
  
  vector<int> newIndexes(newSize-oldSize);
  iota(newIndexes.begin(), newIndexes.end(), oldSize);
  
  impl->playlist.insert(impl->playlist.begin()+pos, newIndexes.begin(), newIndexes.end());
  
  impl->shuffled.insert(impl->shuffled.end(), newIndexes.begin(), newIndexes.end());
  
  vector<int>::iterator it;
  if (currentItem == -1) {
    it = impl->shuffled.begin();
  } else {
    it = find(impl->shuffled.begin(), impl->shuffled.end(), currentItem) + 1;
  }
  
  random_shuffle(it, impl->shuffled.end());
}

- (void)traverseNodeAndAddItems:(int)node {
  int song = [[Tree sharedTree] songFromNode:node];
  
  if (song == -1) {
    int n = [[Tree sharedTree] numberOfChildrenForNode:node];
    for (int i = 0; i < n; ++i) {
      [self traverseNodeAndAddItems:[[Tree sharedTree] childAtIndex:i forNode:node]];
    }
  } else {
    PlaylistItem *pi = [[PlaylistItem alloc] initWithLibrarySong:song];
    impl->playlistItems.push_back(pi);
  }
}

- (int)reorderSongs:(NSArray *)rows atPos:(int)pos {
  [self resetCurrentItemIfStopped];
  
  vector<int> tmp;
  
  int len = (int)impl->playlist.size();
  int rowsLen = (int)rows.count;
  int j = 0, k = 0, posDelta = 0;
  
  for (int i = 0; i < len; ++i) {
    int nextRow = (j < rowsLen)? [rows[j] intValue]: len;
    if (i == nextRow) {
      if (i < pos) ++posDelta;
      tmp.push_back(impl->playlist[nextRow]);
      ++j;
    } else {
      if (i != k) impl->playlist[k] = impl->playlist[i];
      ++k;
    }
  }
  
  for(; k < len; ++k ) impl->playlist.pop_back();
  pos -= posDelta;
  impl->playlist.insert(impl->playlist.begin()+pos, tmp.begin(), tmp.end());
  return pos;
}

- (void)sortBy:(NSString *)str {
  [self resetCurrentItemIfStopped];
  
  BOOL isLength = [str isEqualToString:@"length"];
  BOOL isTrackNumber = [str isEqualToString:@"track number"];
  int tagIndex = [Tags indexFromTagName:str];
  
  sort(impl->playlist.begin(), impl->playlist.end(), [&, tagIndex, isLength, isTrackNumber](int a, int b) -> bool {
    PlaylistItem *p1 = impl->playlistItems[a];
    PlaylistItem *p2 = impl->playlistItems[b];
    
    if (isLength) return p1.lengthInSeconds < p2.lengthInSeconds;
    
    NSString *val1 = [p1.tags tagValueForIndex:tagIndex];
    NSString *val2 = [p2.tags tagValueForIndex:tagIndex];
    
    if (isTrackNumber) return val1.intValue < val2.intValue;
    return [val1 caseInsensitiveCompare:val2] == NSOrderedAscending;
  });
}

- (void)reverse {
  [self resetCurrentItemIfStopped];  
  reverse(impl->playlist.begin(), impl->playlist.end());
}

- (void)removeSongsAtIndexes:(NSIndexSet *)indexes {
  [self resetCurrentItemIfStopped];
  
  vector<int> indexesToRemove;
  for (NSInteger curr = indexes.firstIndex; curr != NSNotFound; curr = [indexes indexGreaterThanIndex:curr]) {
    indexesToRemove.push_back((int)curr);
    if (impl->playlist[curr] == currentItem) currentItem = -1;
  }
  
  int n = (int)indexesToRemove.size();
  int m = self.numberOfItems;
  
  vector<int> itemIndexesToRemoveMask(m, 0);
  for (auto it = indexesToRemove.begin(); it != indexesToRemove.end(); ++it)
    itemIndexesToRemoveMask[impl->playlist[*it]] = 1;
  
  vector<int> itemIndexesToRemove;
  vector<int> shuffledIndexesToRemove;
  for (int i = 0; i < m; ++i) {
    if (itemIndexesToRemoveMask[impl->shuffled[i]]) shuffledIndexesToRemove.push_back(i);
    if (itemIndexesToRemoveMask[i]) itemIndexesToRemove.push_back(i);
  }
  
  removeIndexesFromVector(itemIndexesToRemove, impl->playlistItems);
  removeIndexesFromVector(indexesToRemove, impl->playlist);
  removeIndexesFromVector(shuffledIndexesToRemove, impl->shuffled);
  
  for (int i = 1; i < m; ++i) itemIndexesToRemoveMask[i] += itemIndexesToRemoveMask[i-1];
  if (currentItem != -1) currentItem -= itemIndexesToRemoveMask[currentItem];
  for (int i = 0; i < m-n; ++i) {
    impl->playlist[i] -= itemIndexesToRemoveMask[impl->playlist[i]];
    impl->shuffled[i] -= itemIndexesToRemoveMask[impl->shuffled[i]];
  }
}

template <typename T>
static void removeIndexesFromVector(vector<int> &r, vector<T> &v) {
  int waitingForIndex = 0;
  int overwritePos = 0;
  int vs = (int)v.size();
  int rs = (int)r.size();
  for (int i = 0; i < vs; ++i) {
    if (waitingForIndex < rs && i == r[waitingForIndex]) {
      ++waitingForIndex;
    } else {
      v[overwritePos++] = v[i];
    }
  }
  v.resize(vs - rs);
}

- (void)resetCurrentItemIfStopped {
  if ([[FilePlayer sharedPlayer] stopped]) currentItem = -1;
}

#pragma mark - playing songs

- (int)numberOfItems {
  return (int)impl->playlistItems.size();
}

- (PlaylistItem *)moveToItemWithIndex:(int)index {
  currentItem = impl->playlist[index];
  return [self currentItem];
}

- (PlaylistItem *)objectAtIndexedSubscript:(int)index {
  return impl->playlistItems[impl->playlist[index]];
}

- (PlaylistItem *)currentItem {
  if (currentItem == -1) return nil;
  return impl->playlistItems[currentItem];
}

- (PlaylistItem *)moveToNextItem {
  return [self moveToItemWithDelta:1];
}

- (PlaylistItem *)moveToPrevItem {
  return [self moveToItemWithDelta:-1];
}

- (PlaylistItem *)moveToFirstItem {
  if (self.numberOfItems == 0) return nil;
  return impl->playlistItems[currentItem = impl->playlist[0]];
}

- (void)forgetCurrentItem {
  currentItem = -1;
}

- (PlaylistItem *)moveToItemWithDelta:(int)delta {
  if (currentItem == -1) return nil;

  BOOL shuffled = [PlaylistManager sharedManager].shuffle;
  BOOL repeat = [PlaylistManager sharedManager].repeat;
  
  vector<int> &order = shuffled? impl->shuffled: impl->playlist;
  
  int n = (int)order.size();
  int pos = (int) (find(order.begin(), order.end(), currentItem) - order.begin()) + delta;
  if (pos == -1 || pos == n) {
    if (repeat) pos = (pos+n)%n;
    else {
      currentItem = -1;
      return nil;
    }
  }

  return impl->playlistItems[currentItem = order[pos]];
}

@end
