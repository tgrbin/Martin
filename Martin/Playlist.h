//
//  Playlist.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PlaylistItem;
struct PlaylistImpl;

@interface Playlist : NSObject {
  int suggestedItemIndex; // ako se izbrise pjesma koja trenutno svira, koji item da svira sljedeci
  BOOL currentItemIndexRemoved;
  
  struct PlaylistImpl *impl;
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) int currentItemIndex;

- (id)initWithName:(NSString *)n array:(NSArray *)s;
- (void)addTreeNodes:(NSArray *)treeNodes atPos:(int)pos;

- (void)removeSongsAtIndexes:(NSIndexSet *)indexes;
- (int)reorderSongs:(NSArray *)rows atPos:(int)pos;
- (void)sortBy:(NSString *)str;
- (void)reverse;

- (int)numberOfItems;
- (PlaylistItem *)objectAtIndexedSubscript:(int)index;

- (PlaylistItem *)currentItem;
- (PlaylistItem *)nextItemShuffled:(BOOL)shuffled;
- (PlaylistItem *)prevItemShuffled:(BOOL)shuffled;

@end
