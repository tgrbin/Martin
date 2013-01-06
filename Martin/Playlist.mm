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

@implementation Playlist {
  vector<PlaylistItem *> playlistItems;
    
  // these variables hold indexes within playlistItems vector
  int currentItem;
  vector<int> playlist;
  vector<int> shuffled;
}

#pragma mark - init

- (id)initWithName:(NSString *)n andPlaylistItems:(NSArray *)s {
  if (self = [super init]) {
    _name = n;
    currentItem = -1;
    
    for (id item in s) playlistItems.push_back(item);
    
    playlist.resize(s.count);
    [self myIota:playlist start:0];
    [self shuffle];
  }
  return self;
}

- (id)initWithName:(NSString *)n andTreeNodes:(NSArray *)arr {
  if (self = [self init]) {
    [self guessNameAndAddItems:arr];
    _name = n;
  }
  return self;
}

- (id)initWithTreeNodes:(NSArray *)arr {
  if (self = [self init]) {
    [self guessNameAndAddItems:arr];
  }
  return self;
}

- (id)initWithPlaylistItems:(NSArray *)arr {
  if (self = [self initWithName:@"" andPlaylistItems:arr]) {
    [self guessNameAndAddItems:arr];
  }
  return self;
}

- (id)init {
  return [self initWithName:@"new playlist" andPlaylistItems:@[]];
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
      int song = [Tree songFromNode:node];
      if (song != -1) node = [Tree parentOfNode:node];
        
      folderName = [Tree nameForNode:node];
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
  int oldSize = (int)playlistItems.size();
  for (id item in arr) {
    if ([item isKindOfClass:[PlaylistItem class]]) {
      playlistItems.push_back(item);
    } else {
      [self traverseNodeAndAddItems:[item intValue]];
    }
  }
  int newSize = (int)playlistItems.size();
  
  vector<int> newIndexes(newSize-oldSize);
  [self myIota:newIndexes start:oldSize];
  
  playlist.insert(playlist.begin()+pos, newIndexes.begin(), newIndexes.end());
  
  shuffled.insert(shuffled.end(), newIndexes.begin(), newIndexes.end());
  
  vector<int>::iterator it;
  if (currentItem == -1) {
    it = shuffled.begin();
  } else {
    it = find(shuffled.begin(), shuffled.end(), currentItem) + 1;
  }
  
  random_shuffle(it, shuffled.end());
}


- (void)addItemsFromPlaylist:(Playlist *)p {
  [self addItemsFromPlaylists:@[p] atPos:self.numberOfItems];
}

- (void)addItemsFromPlaylists:(NSArray *)arr atPos:(int)pos {
  @autoreleasepool {
    NSMutableArray *allItems = [NSMutableArray new];
    for (Playlist *p in arr) {
      for (int i = 0; i < p.numberOfItems; ++i) [allItems addObject:p[i]];
    }
    [self addPlaylistItemsOrTreeNodes:allItems atPos:pos];
  }
}

- (void)traverseNodeAndAddItems:(int)node {
  int song = [Tree songFromNode:node];
  
  if (song == -1) {
    int n = [Tree numberOfChildrenForNode:node];
    for (int i = 0; i < n; ++i) {
      [self traverseNodeAndAddItems:[Tree childAtIndex:i forNode:node]];
    }
  } else {
    PlaylistItem *pi = [[PlaylistItem alloc] initWithLibrarySong:song];
    playlistItems.push_back(pi);
  }
}

- (int)reorderSongs:(NSArray *)rows atPos:(int)pos {
  [self resetCurrentItemIfStopped];
  
  vector<int> tmp;
  
  int len = (int)playlist.size();
  int rowsLen = (int)rows.count;
  int j = 0, k = 0, posDelta = 0;
  
  for (int i = 0; i < len; ++i) {
    int nextRow = (j < rowsLen)? [rows[j] intValue]: len;
    if (i == nextRow) {
      if (i < pos) ++posDelta;
      tmp.push_back(playlist[nextRow]);
      ++j;
    } else {
      if (i != k) playlist[k] = playlist[i];
      ++k;
    }
  }
  
  for(; k < len; ++k ) playlist.pop_back();
  pos -= posDelta;
  playlist.insert(playlist.begin()+pos, tmp.begin(), tmp.end());
  return pos;
}

- (void)sortBy:(NSString *)str {
  [self resetCurrentItemIfStopped];
  
  BOOL isLength = [str isEqualToString:@"length"];
  BOOL isTrackNumber = [str isEqualToString:@"track number"];
  int tagIndex = [Tags indexFromTagName:str];
  
  @autoreleasepool {
    sort(playlist.begin(), playlist.end(), [&, tagIndex, isLength, isTrackNumber](int a, int b) -> bool {
      PlaylistItem *p1 = playlistItems[a];
      PlaylistItem *p2 = playlistItems[b];
      
      if (isLength) return p1.lengthInSeconds < p2.lengthInSeconds;
    
      if (p1.p_librarySong != -1 && p2.p_librarySong != -1) {
        struct LibrarySong *s1 = [Tree songDataForP:p1.p_librarySong];
        struct LibrarySong *s2 = [Tree songDataForP:p2.p_librarySong];
        
        if (isTrackNumber) {
          int t1, t2;
          if (sscanf(s1->tags[tagIndex], "%d", &t1) == 1 && sscanf(s2->tags[tagIndex], "%d", &t2) == 1) {
            return t1 < t2;
          } else return strcasecmp(s1->tags[tagIndex], s2->tags[tagIndex]) < 0;
        } else {
          return strcasecmp(s1->tags[tagIndex], s2->tags[tagIndex]) < 0;
        }
      } else {
        NSString *val1 = [p1 tagValueForIndex:tagIndex];
        NSString *val2 = [p2 tagValueForIndex:tagIndex];
        
        if (isTrackNumber) return val1.intValue < val2.intValue;
        return [val1 caseInsensitiveCompare:val2] == NSOrderedAscending;
      }
    });
  }
}

- (void)reverse {
  [self resetCurrentItemIfStopped];  
  reverse(playlist.begin(), playlist.end());
}

- (void)removeSongsAtIndexes:(NSIndexSet *)indexes {
  [self resetCurrentItemIfStopped];
  
  vector<int> indexesToRemove;
  for (NSInteger curr = indexes.firstIndex; curr != NSNotFound; curr = [indexes indexGreaterThanIndex:curr]) {
    indexesToRemove.push_back((int)curr);
    if (playlist[curr] == currentItem) currentItem = -1;
  }
  
  int n = (int)indexesToRemove.size();
  int m = self.numberOfItems;
  
  vector<int> itemIndexesToRemoveMask(m, 0);
  for (auto it = indexesToRemove.begin(); it != indexesToRemove.end(); ++it)
    itemIndexesToRemoveMask[playlist[*it]] = 1;
  
  vector<int> itemIndexesToRemove;
  vector<int> shuffledIndexesToRemove;
  for (int i = 0; i < m; ++i) {
    if (itemIndexesToRemoveMask[shuffled[i]]) shuffledIndexesToRemove.push_back(i);
    if (itemIndexesToRemoveMask[i]) itemIndexesToRemove.push_back(i);
  }
  
  removeIndexesFromVector(itemIndexesToRemove, playlistItems);
  removeIndexesFromVector(indexesToRemove, playlist);
  removeIndexesFromVector(shuffledIndexesToRemove, shuffled);
  
  for (int i = 1; i < m; ++i) itemIndexesToRemoveMask[i] += itemIndexesToRemoveMask[i-1];
  if (currentItem != -1) currentItem -= itemIndexesToRemoveMask[currentItem];
  for (int i = 0; i < m-n; ++i) {
    playlist[i] -= itemIndexesToRemoveMask[playlist[i]];
    shuffled[i] -= itemIndexesToRemoveMask[shuffled[i]];
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

- (void)shuffle {
  shuffled = playlist;
  srand((unsigned int) time(0));
  random_shuffle(shuffled.begin(), shuffled.end());
  
  if (currentItem != -1) {
    int pos = (int) (find(shuffled.begin(), shuffled.end(), currentItem) - shuffled.begin());
    int t = shuffled[pos];
    shuffled[pos] = shuffled[0];
    shuffled[0] = t;
  }
}

#pragma mark - playing songs

- (int)numberOfItems {
  return (int)playlistItems.size();
}

- (PlaylistItem *)moveToItemWithIndex:(int)index {
  currentItem = playlist[index];
  [self shuffle];
  return [self currentItem];
}

- (PlaylistItem *)objectAtIndexedSubscript:(int)index {
  return playlistItems[playlist[index]];
}

- (PlaylistItem *)currentItem {
  if (currentItem == -1) return nil;
  return playlistItems[currentItem];
}

- (PlaylistItem *)moveToNextItem {
  return [self moveToItemWithDelta:1];
}

- (PlaylistItem *)moveToPrevItem {
  return [self moveToItemWithDelta:-1];
}

- (PlaylistItem *)moveToFirstItem {
  if (self.numberOfItems == 0) return nil;
  return playlistItems[currentItem = playlist[0]];
}

- (void)forgetCurrentItem {
  currentItem = -1;
}

- (PlaylistItem *)moveToItemWithDelta:(int)delta {
  if (currentItem == -1) return nil;

  BOOL shuffle = [PlaylistManager sharedManager].shuffle;
  BOOL repeat = [PlaylistManager sharedManager].repeat;
  
  vector<int> &order = shuffle? shuffled: playlist;
  
  int n = (int)order.size();
  int pos = (int) (find(order.begin(), order.end(), currentItem) - order.begin()) + delta;
  if (pos == -1 || pos == n) {
    if (repeat) pos = (pos+n)%n;
    else {
      currentItem = -1;
      return nil;
    }
  }

  return playlistItems[currentItem = order[pos]];
}

- (void)myIota:(vector<int>&) v start:(int)s {
  size_t n = v.size();
  for (int i = 0; i < n; ++i) v[i] = s+i;
}

@end
