//
//  Playlist.m
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Playlist.h"
#import "TreeLeaf.h"
#import "TreeNode.h"
#import "Song.h"
#import "LibManager.h"
#import "PlaylistItem.h"

#import <algorithm>
#import <vector>
#import <numeric>
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

- (id)initWithName:(NSString *)n array:(NSArray *)s {
  if( self = [super init] ) {
    _name = n;
    impl = new PlaylistImpl();

    _currentItemIndex = s.count > 0? 0: -1;
    
    for (id item in s) {
      impl->playlistItems.push_back([[PlaylistItem alloc] initWithDictionary:item]);
    }
    
    impl->playlist.resize(s.count);
    iota(impl->playlist.begin(), impl->playlist.end(), 0);
    impl->shuffled = impl->playlist;
    random_shuffle(impl->shuffled.begin(), impl->shuffled.end());
  }
  return self;
}

- (id)init {
  return [self initWithName:@"new playlist" array:@[]];
}

#pragma mark - manage playlist

- (void)addTreeNodes:(NSArray *)treeNodes atPos:(int)pos {
  int oldSize = (int)impl->playlistItems.size();
  for (TreeNode *t in treeNodes) [self traverseNodeAndAddItems:t];
  int newSize = (int)impl->playlistItems.size();
  
  vector<int> newIndexes(newSize-oldSize);
  iota(newIndexes.begin(), newIndexes.end(), oldSize);

  impl->playlist.insert(impl->playlist.begin()+pos, newIndexes.begin(), newIndexes.end());
  
  impl->shuffled.insert(impl->shuffled.end(), newIndexes.begin(), newIndexes.end());
  
  vector<int>::iterator it;
  if (_currentItemIndex == -1) {
    _currentItemIndex = 0;
    it = impl->shuffled.begin();
  } else {
    it = find(impl->shuffled.begin(), impl->shuffled.end(), _currentItemIndex);
  }
  
  random_shuffle(it, impl->shuffled.end());
}

- (void)traverseNodeAndAddItems:(TreeNode *)node {
  if ([node isKindOfClass:[TreeLeaf class]]) {
    PlaylistItem *pi = [PlaylistItem new];
    pi.inode = ((TreeLeaf*)node).song.inode;
    impl->playlistItems.push_back(pi);
  } else {
    int n = node.nChildren;
    for (int i = 0; i < n; ++i) {
      [self traverseNodeAndAddItems:[node getChild:i]];
    }
  }
}

- (int)reorderSongs:(NSArray *)rows atPos:(int)pos {
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
  BOOL isLength = [str isEqualToString:@"length"];
  BOOL isTrackNumber = [str isEqualToString:@"track number"];
  
  sort(impl->playlist.begin(), impl->playlist.end(), [=](int a, int b) -> bool {
    PlaylistItem *p1 = impl->playlistItems[a];
    PlaylistItem *p2 = impl->playlistItems[b];
    
    if (isLength) return p1.lengthInSeconds > p2.lengthInSeconds;
    
    NSString *val1 = p1.tags[str];
    NSString *val2 = p2.tags[str];
    
    if (isTrackNumber) return val1.intValue > val2.intValue;
    return [val1 caseInsensitiveCompare:val2] == NSOrderedAscending;
  });
}

- (void)reverse {
  reverse(impl->playlist.begin(), impl->playlist.end());
}

- (void)removeSongsAtIndexes:(NSIndexSet *)indexes {
  currentItemIndexRemoved = NO;
  
  vector<int> indexesToRemove;
  for (NSInteger curr = indexes.firstIndex; curr != NSNotFound; curr = [indexes indexGreaterThanIndex:curr]) indexesToRemove.push_back((int)curr);

  BOOL found = NO;
  int nextAvailable = -1;
  for (int i = 0; i < indexesToRemove.size(); ++i) {
    if (impl->playlist[indexesToRemove[i]] == _currentItemIndex) found = YES;
    if (found == YES && i < indexesToRemove.size()-1 && indexesToRemove[i+1] != indexesToRemove[i]+1) {
      nextAvailable = indexesToRemove[i]+1;
      break;
    }
  }
  if (found == YES && nextAvailable == -1 && indexesToRemove[0] != 0) nextAvailable = indexesToRemove[0];
  
  if (found) {
    currentItemIndexRemoved = YES;
    if (nextAvailable != -1) suggestedItemIndex = impl->playlist[nextAvailable];
  }
  
  set<int> itemIndexesToRemoveSet;
  vector<int> itemIndexesToRemoveVector((int)indexesToRemove.size());
  for (auto it = indexesToRemove.begin(); it != indexesToRemove.end(); ++it) {
    itemIndexesToRemoveSet.insert(impl->playlist[*it]);
    itemIndexesToRemoveVector.push_back(impl->playlist[*it]);
  }
  
  vector<int> shuffledIndexesToRemove;
  for (int i = 0; i < impl->shuffled.size(); ++i)
    if (itemIndexesToRemoveSet.count(impl->shuffled[i])) shuffledIndexesToRemove.push_back(i);

  removeIndexesFromVector(itemIndexesToRemoveVector, impl->playlistItems);
  removeIndexesFromVector(indexesToRemove, impl->playlist);
  removeIndexesFromVector(shuffledIndexesToRemove, impl->shuffled);
}

template <typename T>
static void removeIndexesFromVector(vector<int> &r, vector<T> &v) {
  int waitingForIndex = 0;
  int overwritePos = 0;
  for (int i = 0; i < v.size(); ++i) {
    if (i == r[waitingForIndex]) {
      ++waitingForIndex;
    } else {
      v[i] = v[overwritePos++];
    }
  }
  v.resize(v.size() - r.size());
}

#pragma mark - playing songs

- (int)numberOfItems {
  return (int)impl->playlistItems.size();
}

- (PlaylistItem *)objectAtIndexedSubscript:(int)index {
  return impl->playlistItems[impl->playlist[index]];
}

- (void)setCurrentItemIndex:(int)index {
  _currentItemIndex = index;
  currentItemIndexRemoved = NO;
}

- (PlaylistItem *)currentItem {
  if (_currentItemIndex == -1) return nil;
  return impl->playlistItems[impl->playlist[_currentItemIndex]];
}

- (PlaylistItem *)nextItemShuffled:(BOOL)shuffled {
  return [self itemAfterCurrentOneShuffled:shuffled next:YES];
}

- (PlaylistItem *)prevItemShuffled:(BOOL)shuffled {
  return [self itemAfterCurrentOneShuffled:shuffled next:NO];
}

- (PlaylistItem *)itemAfterCurrentOneShuffled:(BOOL)shuffled next:(BOOL)next {
  if (_currentItemIndex == -1) return nil;

  vector<int> &order = shuffled? impl->shuffled: impl->playlist;
  
  int pos = 0;
  int lookFor;
  if (currentItemIndexRemoved == YES) {
    currentItemIndexRemoved = NO;
    pos = next? -1: 0;
    lookFor = suggestedItemIndex;
  } else {
    lookFor = _currentItemIndex;
  }
  
  int n = (int)order.size();
  pos += (find(order.begin(), order.end(), lookFor) - order.begin());
  pos = (pos + (next? 1: -1) + n) % n;
  
  return impl->playlistItems[_currentItemIndex = order[pos]];
}

@end
