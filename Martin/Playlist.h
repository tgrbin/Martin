//
//  Playlist.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PlaylistItem;

@interface Playlist : NSObject

@property (nonatomic, strong) NSString *name;

- (id)initWithName:(NSString *)n andPlaylistItems:(NSArray *)arr;
- (id)initWithName:(NSString *)n andTreeNodes:(NSArray *)arr;

- (id)initWithTreeNodes:(NSArray *)arr; // these two method suggest playlist name based on items
- (id)initWithPlaylistItems:(NSArray *)arr;

// these methods return number of items added
- (int)addPlaylistItems:(NSArray *)arr;
- (int)addPlaylistItems:(NSArray *)arr atPos:(int)pos;
- (int)addItemsFromPlaylist:(Playlist *)p;
- (int)addItemsFromPlaylists:(NSArray *)arr atPos:(int)pos;
- (int)addTreeNodes:(NSArray *)treeNodes;
- (int)addTreeNodes:(NSArray *)treeNodes atPos:(int)pos;

// returns the actual position where items landed
- (int)reorderItemsAtRows:(NSArray *)rows toPos:(int)pos;

- (void)removeFirstItem;
- (void)removeSongsAtIndexes:(NSIndexSet *)indexes;
- (void)sortBy:(NSString *)str;
- (void)reverse;

- (int)numberOfItems;
- (BOOL)isEmpty;
- (PlaylistItem *)objectAtIndexedSubscript:(int)index;

- (PlaylistItem *)currentItem;
- (PlaylistItem *)moveToNextItem;
- (PlaylistItem *)moveToPrevItem;
- (PlaylistItem *)moveToFirstItem;
- (PlaylistItem *)moveToItemWithIndex:(int)index;

- (void)shuffle;

- (int)currentItemIndex;

@end
