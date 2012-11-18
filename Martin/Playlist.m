//
//  Playlist.m
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <stdlib.h>
#import "Playlist.h"
#import "TreeLeaf.h"
#import "TreeNode.h"
#import "Song.h"
#import "LibManager.h"

@implementation Playlist

#pragma mark - init

- (id)initWithName:(NSString *)n array:(NSArray *)s {
  if( self = [super init] ) {
    _name = n;
    _tmpAddSongs = [NSMutableArray new];
    _songs = [[NSMutableArray alloc] initWithArray:s];
    _songsSet = [[NSMutableSet alloc] initWithArray:s];

    _currentID = s.count > 0? [[_songs objectAtIndex:0] intValue]: -1;
    
    _shuffledSongs = [[NSMutableArray alloc] initWithArray:_songs];
    for( int i = 0; i < _shuffledSongs.count; ++i ) {
      int j = i + arc4random() % (_shuffledSongs.count-i);
      [_shuffledSongs exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
  }
  return self;
}

- (id)init {
  return [self initWithName:@"new playlist" array:@[]];
}

#pragma mark - manage playlist

- (void)addSongs:(NSArray *)treeNodes atPos:(NSInteger)pos {
  [_tmpAddSongs removeAllObjects];
  
  for (TreeNode *t in treeNodes) find_songs(t, self);
  
  [self insertArray:_tmpAddSongs atPos:pos];
  
  int shuffledPosition = (int)[_shuffledSongs indexOfObject:[NSNumber numberWithInt:_currentID]];
  [_shuffledSongs addObjectsFromArray:_tmpAddSongs];
  
  for (int i = shuffledPosition+1; i < _shuffledSongs.count; ++i ) {
    int j = i + arc4random() % (_shuffledSongs.count-i);
    [_shuffledSongs exchangeObjectAtIndex:i withObjectAtIndex:j];
  }
  
  if (_currentID == -1) _currentID = [[_songs objectAtIndex:0] intValue];
}

- (void)insertArray:(NSArray *)arr atPos:(NSInteger)pos {
  int tmpLen = (int)arr.count;
  int len = (int)_songs.count;
  
  for (int i = 0; i < tmpLen; ++i) [_songs addObject:@0];
  
  for (int i = len+tmpLen-1; i >= pos+tmpLen; --i) {
    [_songs replaceObjectAtIndex:i withObject:[_songs objectAtIndex:i-tmpLen]];
  }
  
  for (int i = (int)pos; i < pos+tmpLen; ++i) {
    [_songs replaceObjectAtIndex:i withObject:[arr objectAtIndex:i-pos]];
  }
}

- (int)reorderSongs:(NSArray*)rows atPos:(NSInteger)pos {
  NSMutableArray *tmpArr = [NSMutableArray new];

  int len = (int)_songs.count;
  int rowsLen = (int)rows.count;
  int j = 0, k = 0, posDelta = 0;
  
  for (int i = 0; i < len; ++i) {
    int nextRow = (j<rowsLen)? [[rows objectAtIndex:j] intValue]: len;
    if( i == nextRow ) {
      if (i < pos ) ++posDelta;
      [tmpArr addObject:[_songs objectAtIndex:nextRow]];
      ++j;
    } else {
      if (i != k) [_songs replaceObjectAtIndex:k withObject:[_songs objectAtIndex:i]];
      ++k;
    }
  }
  
  for(; k < len; ++k ) [_songs removeLastObject];
  pos -= posDelta;
  [self insertArray:tmpArr atPos:pos];
  return (int)pos;
}

static void find_songs( TreeNode *node, Playlist *p ) {
  if ([node isKindOfClass:[TreeLeaf class]]) {
    NSNumber *songID = @(((TreeLeaf*)node).song.inode);
    
    if (![p.songsSet containsObject:songID]) {
      [p.songsSet addObject:songID];
      [p.tmpAddSongs addObject:songID];
    }
  } else {
    int n = node.nChildren;
    for (int i = 0; i < n; ++i) {
      find_songs([node getChild:i], p);
    }
  }
}

- (void)sortBy:(NSString *)str {
  [_songs sortUsingComparator:^NSComparisonResult(id id1, id id2) {
    Song *s1 = [[LibManager sharedManager] songByID:[id1 intValue]];
    Song *s2 = [[LibManager sharedManager] songByID:[id2 intValue]];
    
    if ([str isEqualToString:@"length"]) return s1.lengthInSeconds > s2.lengthInSeconds;

    NSString *val1 = [s1.tagsDictionary objectForKey:str];
    NSString *val2 = [s2.tagsDictionary objectForKey:str];
    
    if ([str isEqualToString:@"track number"]) return [val1 intValue] > [val2 intValue];
    
    return [val1 caseInsensitiveCompare:val2];
  }];
}

- (void)reverse {
  int n = (int) _songs.count;
  for (int i = 0; i+i < n; ++i) {
    [_songs exchangeObjectAtIndex:i withObjectAtIndex:n-i-1];
  }
}

- (void)removeSongsAtIndexes:(NSIndexSet *)indexes {
  currentIDRemoved = NO;
  
  NSUInteger curr = indexes.firstIndex;
  int pos;
  while (curr != NSNotFound) {
    NSNumber *song = [_songs objectAtIndex:curr];
    if (song.intValue == _currentID || (currentIDRemoved == YES && song.intValue == suggestedID)) {
      currentIDRemoved = YES;
      suggestedID = song.intValue;
      pos = (int) curr;
    }
    [_songsSet removeObject:song];
    curr = [indexes indexGreaterThanIndex:curr];
  }

  if (currentIDRemoved) {
    for(;;) {
      int next = (int) [indexes indexGreaterThanIndex:pos];
      if (next == NSNotFound) {
        if (pos == [_songs count]-1) pos = -1;
      } else {
        if (next == pos+1) { ++pos; continue; }
      }
      ++pos;
      break;
    }
    suggestedID = [[_songs objectAtIndex:pos] intValue];
  }
  
  [_songs removeObjectsAtIndexes:indexes];
  
  NSMutableIndexSet *shuffledIndexes = [NSMutableIndexSet new];
  for (int i = 0; i < [_shuffledSongs count]; ++i) {
    if (![_songsSet containsObject:[_shuffledSongs objectAtIndex:i]]) [shuffledIndexes addIndex:i];
  }
  [_shuffledSongs removeObjectsAtIndexes:shuffledIndexes];
}

#pragma mark - playing songs

- (int)nextSongIDShuffled:(BOOL)shuffled {
  return [self songAfterCurrentOneShuffled:shuffled next:YES];
}

- (int)prevSongIDShuffled:(BOOL)shuffled {
  return [self songAfterCurrentOneShuffled:shuffled next:NO];
}

- (int)songAfterCurrentOneShuffled:(BOOL)shuffled next:(BOOL)next {
  if( _currentID == -1 ) return -1;
  
  NSArray *arr = shuffled? _shuffledSongs: _songs;
  int pos;
  
  if (currentIDRemoved == YES) {
    currentIDRemoved = NO;
    pos = (int) [arr indexOfObject:@(suggestedID)] - (next? 1: 0);
  } else {
    pos = (int) [arr indexOfObject:@(_currentID)];
  }
  
  return _currentID = [(NSNumber*)[arr objectAtIndex:(pos+(next? 1: -1))%arr.count] intValue];
}

- (void)setCurrentSong:(int)index {
  _currentID = (int) [[_songs objectAtIndex:index] intValue];
}

@end
