//
//  Playlist.m
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//

#import "Playlist.h"
#import "Playlist+private.h"

#import "MartinAppDelegate.h"
#import "LibManager.h"
#import "PlaylistItem.h"
#import "LibraryTree.h"
#import "LibrarySong.h"
#import "Tags.h"
#import "PlaylistNameGuesser.h"
#import "LibraryOutlineViewDataSource.h"

#import <algorithm>
#import <numeric>
#import <set>

extern NSString * const kPlaylistCurrentItemChanged = @"PlaylistCurrentItemChanged";

using namespace std;

@interface Playlist()
@property (nonatomic, assign) int currentIndexInPlaylistItems;
@end

@implementation Playlist

#pragma mark - file stream init and output

- (id)initWithFileStream:(FILE *)f {
  if (self = [super init]) {
    char buff[1024];
    fgets(buff, 1024, f);
    buff[strlen(buff)-1] = 0;
    _name = @(buff);
    
    int nItems;
    fscanf(f, "%d%d%d\n", &nItems, &_currentIndexInPlaylistItems, &_currentItemIndex);
    for (int i = 0; i < nItems; ++i) {
      playlistItems.push_back([[PlaylistItem alloc] initWithFileStream:f]);
    }
    [self readVector:playlist fromFileStream:f];
    [self readVector:playedItems fromFileStream:f];
  }
  
  return self;
}

- (void)outputToFileStream:(FILE *)f {
  fprintf(f, "%s\n", [_name UTF8String]);
  fprintf(f, "%d %d %d\n", self.numberOfItems, _currentIndexInPlaylistItems, _currentItemIndex);
  for (int i = 0; i < self.numberOfItems; ++i) {
    [playlistItems[i] outputToFileStream:f];
  }
  [self outputVector:playlist toFileStream:f];
  [self outputVector:playedItems toFileStream:f];
}

- (void)outputVector:(vector<int>&)v toFileStream:(FILE *)f {
  int n = (int)v.size();
  fprintf(f, "%d\n", n);
  for (int i = 0; i < n; ++i) {
    fprintf(f, "%d", v[i]);
    fprintf(f, i == n-1? "\n": " ");
  }
}

- (void)readVector:(vector<int>&)v fromFileStream:(FILE *)f {
  int n;
  fscanf(f, "%d\n", &n);
  for (int i = 0; i < n; ++i) {
    int x;
    fscanf(f, "%d", &x);
    v.push_back(x);
    if (i == n-1) fscanf(f, "\n");
  }
}

#pragma mark - init

- (id)initWithName:(NSString *)n andPlaylistItems:(NSArray *)s {
  if (self = [super init]) {
    _name = n;
    self.currentIndexInPlaylistItems = -1;
    
    for (id item in s) playlistItems.push_back(item);
    
    playlist.resize(s.count);
    [self myIota:playlist start:0];
  }
  return self;
}

- (id)initWithName:(NSString *)n andTreeNodes:(NSArray *)arr {
  if (self = [self init]) {
    [PlaylistNameGuesser guessNameAndAddItems:arr toPlaylist:self];
    _name = n;
  }
  return self;
}

- (id)initWithTreeNodes:(NSArray *)arr andSuggestedName:(NSString *)name {
  if (self = [self init]) {
    if ([PlaylistNameGuesser guessNameAndAddItems:arr toPlaylist:self] == NO) {
      _name = [name capitalizedString];
    }
  }
  return self;
}

- (id)initWithTreeNodes:(NSArray *)arr {
  if (self = [self init]) {
    [PlaylistNameGuesser guessNameAndAddItems:arr toPlaylist:self];
  }
  return self;
}

- (id)initWithPlaylistItems:(NSArray *)arr {
  if (self = [self initWithName:@"" andPlaylistItems:arr]) {
    [PlaylistNameGuesser guessNameAndAddItems:arr toPlaylist:self];
  }
  return self;
}

- (id)init {
  return [self initWithName:@"New playlist" andPlaylistItems:@[]];
}

#pragma mark - adding and removing items

- (int)addPlaylistItems:(NSArray *)arr {
  return [self addPlaylistItems:arr atPos:self.numberOfItems];
}

- (int)addPlaylistItems:(NSArray *)arr atPos:(int)pos {
  return [self addPlaylistItemsOrTreeNodes:arr atPos:pos];
}

- (int)addTreeNodes:(NSArray *)treeNodes {
  return [self addTreeNodes:treeNodes atPos:self.numberOfItems];
}

- (int)addTreeNodes:(NSArray *)treeNodes atPos:(int)pos {
  return [self addPlaylistItemsOrTreeNodes:treeNodes atPos:pos];
}

- (int)addPlaylistItemsOrTreeNodes:(NSArray *)arr atPos:(int)pos {
  return [self addPlaylistItems:arr atPos:pos fromPlaylist:nil];
}

- (int)addPlaylistItems:(NSArray *)arr fromPlaylist:(Playlist *)_playlist {
  return [self addPlaylistItems:arr atPos:self.numberOfItems fromPlaylist:_playlist];
}

- (int)addPlaylistItems:(NSArray *)arr atPos:(int)pos fromPlaylist:(Playlist *)_playlist {
  if (arr.count == 0) return 0;
  
  [self resetSortState];
  
  BOOL addingPlaylistItems = [arr[0] isKindOfClass:[PlaylistItem class]];
  
  int oldSize = (int)playlistItems.size();
  for (id item in arr) {
    if (addingPlaylistItems) {
      playlistItems.push_back(item);
      if (isQueue) itemOrigin.push_back(_playlist);
    } else {
      [self traverseNodeAndAddItems:[item intValue]];
    }
  }
  int newSize = (int)playlistItems.size();
  
  vector<int> newIndexes(newSize-oldSize);
  [self myIota:newIndexes start:oldSize];
  
  playlist.insert(playlist.begin()+pos, newIndexes.begin(), newIndexes.end());
  
  [self playlistChanged];
  return newSize - oldSize;  
}

- (int)addItemsFromPlaylist:(Playlist *)p {
  return [self addItemsFromPlaylists:@[p] atPos:self.numberOfItems];
}

- (int)addItemsFromPlaylists:(NSArray *)arr atPos:(int)pos {
  @autoreleasepool {
    NSMutableArray *allItems = [NSMutableArray new];
    for (Playlist *p in arr) {
      for (int i = 0; i < p.numberOfItems; ++i) [allItems addObject:p[i]];
    }
    return [self addPlaylistItemsOrTreeNodes:allItems atPos:pos];
  }
}

- (void)traverseNodeAndAddItems:(int)node {
  LibraryOutlineViewDataSource *dataSource = [MartinAppDelegate get].libraryOutlineViewManager.dataSource;
  
  [dataSource enumeratePlaylistItemsFromItem:@(node)
                                   withBlock:^(PlaylistItem *playlistItem) {
                                     playlistItems.push_back(playlistItem);
                                     if (isQueue) itemOrigin.push_back(nil);
                                   }];
}

- (int)reorderItemsAtRows:(NSArray *)rows toPos:(int)pos {
  [self resetSortState];
  
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
  
  [self playlistChanged];
  return pos;
}

- (void)shuffleIndexes:(NSIndexSet *)indexSet {
  [self resetSortState];
  
  vector<int> indexes;
  vector<int> items;
  for (NSInteger curr = indexSet.firstIndex; curr != NSNotFound; curr = [indexSet indexGreaterThanIndex:curr]) {
    indexes.push_back((int)curr);
    items.push_back(playlist[curr]);
  }
  
  srand((int)time(0));
  random_shuffle(items.begin(), items.end());
  for (int i = 0; i < indexes.size(); ++i) playlist[indexes[i]] = items[i];
  
  [self playlistChanged];
}

- (void)removeSongsAtIndexes:(NSIndexSet *)indexes {
  vector<int> indexesToRemove;
  for (NSInteger curr = indexes.firstIndex; curr != NSNotFound; curr = [indexes indexGreaterThanIndex:curr]) {
    indexesToRemove.push_back((int)curr);
    if (curr == _currentItemIndex) self.currentIndexInPlaylistItems = -1;
  }
  
  int m = self.numberOfItems;
  
  vector<int> itemIndexesToRemoveMask(m, 0);
  for (auto it = indexesToRemove.begin(); it != indexesToRemove.end(); ++it) {
    itemIndexesToRemoveMask[playlist[*it]] = 1;
  }
  
  vector<int> itemIndexesToRemove;
  vector<int> playedItemsIndexesToRemove;
  for (int i = 0; i < m; ++i)
    if (itemIndexesToRemoveMask[i]) itemIndexesToRemove.push_back(i);
  for (int i = 0; i < m; ++i)
    if (i < playedItems.size() && itemIndexesToRemoveMask[playedItems[i]]) playedItemsIndexesToRemove.push_back(i);
  
  for (auto it = itemIndexesToRemove.begin(); it != itemIndexesToRemove.end(); ++it) [playlistItems[*it] cancelID3Read];

  removeIndexesFromVector(playedItemsIndexesToRemove, playedItems);
  removeIndexesFromVector(itemIndexesToRemove, playlistItems);
  removeIndexesFromVector(indexesToRemove, playlist);
  
  if (isQueue) removeIndexesFromVector(itemIndexesToRemove, itemOrigin);
  
  // adjust indexes because some playlistItems are now gone
  for (int i = 1; i < m; ++i) itemIndexesToRemoveMask[i] += itemIndexesToRemoveMask[i-1];
  if (_currentIndexInPlaylistItems != -1) self.currentIndexInPlaylistItems -= itemIndexesToRemoveMask[_currentIndexInPlaylistItems];
  for (int i = 0; i < playlist.size(); ++i) playlist[i] -= itemIndexesToRemoveMask[playlist[i]];
  for (int i = 0; i < playedItems.size(); ++i) playedItems[i] -= itemIndexesToRemoveMask[playedItems[i]];
  
  [self playlistChanged];
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

- (void)playlistChanged {
  // trigger recalculation of currentItemIndex
  self.currentIndexInPlaylistItems = _currentIndexInPlaylistItems;
}

#pragma mark - current item manipulation

- (PlaylistItem *)moveToItemWithIndex:(int)index {
  if (index < 0 || index >= self.numberOfItems) return nil;
  self.currentIndexInPlaylistItems = playlist[index];
  return self.currentItem;
}

- (PlaylistItem *)objectAtIndexedSubscript:(int)index {
  return playlistItems[playlist[index]];
}

- (PlaylistItem *)currentItem {
  if (_currentIndexInPlaylistItems == -1) return nil;
  return playlistItems[_currentIndexInPlaylistItems];
}

- (PlaylistItem *)moveToNextItem {
  return [self moveToItemWithDelta:1];
}

- (PlaylistItem *)moveToPrevItem {
  return [self moveToItemWithDelta:-1];
}

- (PlaylistItem *)moveToFirstItem {
  return [self moveToItemWithIndex:0];
}

- (PlaylistItem *)moveToLastItem {
  return [self moveToItemWithIndex:self.numberOfItems-1];
}

- (PlaylistItem *)moveToItemWithDelta:(int)delta {
  if (self.numberOfItems == 0) return nil;
  
  BOOL shuffle = [MartinAppDelegate get].playerController.shuffle;
  BOOL repeat = [MartinAppDelegate get].playerController.repeat;

  if (_currentIndexInPlaylistItems == -1) {
    if (shuffle) {
      return [self moveToItemWithIndex:arc4random()%self.numberOfItems];
    } else {
      if (delta == 1) return [self moveToFirstItem];
      else return [self moveToLastItem];
    }
  }

  int nextItem = -1;
  
  if (shuffle) {
    if (delta == 1) {
      if (playedItems.size() == playlistItems.size()) { // aready played everything
        playedItems.clear();
        if (repeat) nextItem = arc4random()%playlistItems.size();
      } else {
        nextItem = [self chooseNextShuffledItem];
      }
    } else {
      playedItems.pop_back();
      if (playedItems.size() > 0) {
        nextItem = playedItems.back();
        playedItems.pop_back();
      } else {
        if (repeat) nextItem = arc4random()%playlistItems.size();
      }
    }
  } else {
    int pos = _currentItemIndex + delta;
    int n = (int)playlist.size();
    if (pos == -1 || pos == n) pos = repeat? (pos+n)%n: -1;
    nextItem = pos == -1? -1: playlist[pos];
  }
  
  self.currentIndexInPlaylistItems = nextItem;
  return self.currentItem;
}

// randomly choose item not in playedItems
- (int)chooseNextShuffledItem {
  vector<BOOL> playedItemsMask(playlistItems.size(), NO);
  for (int i = 0; i < playedItems.size(); playedItemsMask[playedItems[i++]] = YES);
  
  int j = arc4random()%(playlistItems.size() - playedItems.size());
  for (int i = 0; i < playlistItems.size(); ++i) {
    if (playedItemsMask[i] == NO)
      if (j-- == 0) return i;
  }
  
  return -1;
}

- (void)findAndSetCurrentItemTo:(PlaylistItem *)item {
  for (int i = 0; i < playlistItems.size(); ++i) {
    if (playlistItems[i] == item) {
      self.currentIndexInPlaylistItems = i;
      return;
    }
  }
}

- (void)addCurrentItemToAlreadyPlayedItems {
  if (_currentIndexInPlaylistItems == -1) return;
  
  int count = 0;
  for (int i = 0; i < playedItems.size(); ++i) {
    if (playedItems[i] == _currentIndexInPlaylistItems) ++count;
    else playedItems[i-count] = playedItems[i];
  }
  playedItems.resize(playedItems.size() - count);
  playedItems.push_back(_currentIndexInPlaylistItems);
}

- (void)setCurrentIndexInPlaylistItems:(int)currentIndexInPlaylistItems {
  _currentIndexInPlaylistItems = currentIndexInPlaylistItems;
  
  if (_currentIndexInPlaylistItems == -1) {
    _currentItemIndex = -1;
  } else {
    for (int i = 0; i < playlist.size(); ++i) {
      if (playlist[i] == _currentIndexInPlaylistItems) {
        _currentItemIndex = i;
      }
    }
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kPlaylistCurrentItemChanged object:nil];
}

#pragma mark - sorting

- (void)sortBy:(NSString *)str {
  if ([_sortedBy isEqualToString:str]) {
    _sortedAscending = !_sortedAscending;
    reverse(playlist.begin(), playlist.end());
  } else {
    _sortedBy = str;
    _sortedAscending = YES;
    
    BOOL isLength = [str isEqualToString:@"length"];
    BOOL isTrackNumber = [str isEqualToString:@"track number"];
    TagIndex tagIndex = [Tags indexFromTagName:str];
    
    @autoreleasepool {
      stable_sort(playlist.begin(), playlist.end(), [&, tagIndex, isLength, isTrackNumber](int a, int b) -> bool {
        PlaylistItem *p1 = playlistItems[a];
        PlaylistItem *p2 = playlistItems[b];
        
        if (isLength) return p1.lengthInSeconds < p2.lengthInSeconds;
        
        if (p1.p_librarySong != -1 && p2.p_librarySong != -1) {
          struct LibrarySong *s1 = [LibraryTree songDataForP:p1.p_librarySong];
          struct LibrarySong *s2 = [LibraryTree songDataForP:p2.p_librarySong];
          
          if (isTrackNumber) {
            const int t1 = [s1->tags[tagIndex] intValue];
            const int t2 = [s2->tags[tagIndex] intValue];
            if (t1 > 0 && t2 > 0) {
              return t1 < t2;
            } else {
              return [s1->tags[tagIndex] caseInsensitiveCompare:s2->tags[tagIndex]] == NSOrderedAscending;
            }
          } else {
            return [s1->tags[tagIndex] caseInsensitiveCompare:s2->tags[tagIndex]] == NSOrderedAscending;
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
  
  [self playlistChanged];
}

- (void)storeIndexes:(NSIndexSet *)indexSet {
  storedIndexes.resize(self.numberOfItems);
  fill(storedIndexes.begin(), storedIndexes.end(), NO);
  for (NSInteger i = [indexSet firstIndex]; i != NSNotFound; i = [indexSet indexGreaterThanIndex:i]) {
    storedIndexes[playlist[i]] = YES;
  }
}

- (NSIndexSet *)indexesAfterSorting {
  NSMutableIndexSet *is = [NSMutableIndexSet new];
  int first = -1, n = self.numberOfItems;
  for (int i = 0; i <= n; ++i) {
    if (i < n && storedIndexes[playlist[i]] == YES) {
      if (first == -1) first = i;
    } else if (first != -1) {
      [is addIndexesInRange:NSMakeRange(first, i-first)];
      first = -1;
    }
  }
  return is;
}

- (void)resetSortState {
  _sortedBy = nil;
}

#pragma mark - other

- (void)cancelID3Reads {
  for (int i = 0; i < playlistItems.size(); ++i) {
    [playlistItems[i] cancelID3Read];
  }
}

- (BOOL)isEmpty {
  return self.numberOfItems == 0;
}

- (int)numberOfItems {
  return (int)playlistItems.size();
}

- (int)numberOfPlayedItems {
  return (int)playedItems.size();
}

- (void)myIota:(vector<int>&) v start:(int)s {
  size_t n = v.size();
  for (int i = 0; i < n; ++i) v[i] = s+i;
}

- (int)indexOfPlaylistItem:(PlaylistItem *)pi {
  if (playlistItemsIndexInitialized == NO) {
    for (int i = 0; i < playlistItems.size(); ++i) {
      playlistItemsIndex.insert(make_pair(playlistItems[i], i));
    }
    playlistItemsIndexInitialized = YES;
  }

  map<PlaylistItem *, int>::iterator it = playlistItemsIndex.find(pi);
  if (it == playlistItemsIndex.end()) return -1;
  return it->second;
}

- (void)forgetPlayedItems {
  playedItems.clear();
}

- (BOOL)isQueue {
  return isQueue;
}

@end
