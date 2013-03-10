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

// these two method suggest playlist name based on items
- (id)initWithTreeNodes:(NSArray *)arr;
- (id)initWithPlaylistItems:(NSArray *)arr;

// these methods return number of items added
- (int)addPlaylistItems:(NSArray *)arr;
- (int)addPlaylistItems:(NSArray *)arr atPos:(int)pos;
- (int)addPlaylistItems:(NSArray *)arr fromPlaylist:(Playlist *)playlist;
- (int)addPlaylistItems:(NSArray *)arr atPos:(int)pos fromPlaylist:(Playlist *)playlist;
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

// used when item from playlist is played from queue
- (void)findAndSetCurrentItemTo:(PlaylistItem *)item;

- (void)cancelID3Reads;

@end

@interface QueuePlaylist : Playlist

- (Playlist *)currentItemPlaylist;

@end
