//
//  Playlist.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//

// C++ header, included only by QueuePlaylist.mm and Playlist.mm
// Other clients should use PlaylistPublic.h

#import <Foundation/Foundation.h>

extern NSString * const kPlaylistCurrentItemChanged;

@class PlaylistItem;

@interface Playlist : NSObject

@property (nonatomic, strong) NSString *name;

- (id)initWithFileStream:(FILE *)f;
- (void)outputToFileStream:(FILE *)f;

- (id)initWithName:(NSString *)n andPlaylistItems:(NSArray *)arr;
- (id)initWithName:(NSString *)n andTreeNodes:(NSArray *)arr;
- (id)initWithTreeNodes:(NSArray *)arr andSuggestedName:(NSString *)name;

// these two method suggest playlist name based on items
- (id)initWithTreeNodes:(NSArray *)arr;
- (id)initWithPlaylistItems:(NSArray *)arr;

// these methods return number of items added
- (int)addPlaylistItems:(NSArray *)arr;
- (int)addPlaylistItems:(NSArray *)arr atPos:(int)pos;
- (int)addPlaylistItems:(NSArray *)arr fromPlaylist:(Playlist *)playlist;
- (int)addPlaylistItems:(NSArray *)arr atPos:(int)pos fromPlaylist:(Playlist *)playlist;
- (int)addTreeNodes:(NSArray *)treeNodes;
- (int)addTreeNodes:(NSArray *)treeNodes atPos:(int)pos;
- (int)addItemsFromPlaylist:(Playlist *)p;
- (int)addItemsFromPlaylists:(NSArray *)arr atPos:(int)pos;

- (void)shuffleIndexes:(NSIndexSet *)indexes;
- (void)removeSongsAtIndexes:(NSIndexSet *)indexes;

// returns the actual position where items landed
- (int)reorderItemsAtRows:(NSArray *)rows toPos:(int)pos;

- (void)sortBy:(NSString *)str;

- (int)numberOfItems;
- (BOOL)isEmpty;
- (PlaylistItem *)objectAtIndexedSubscript:(int)index;

- (int)numberOfPlayedItems;
- (void)forgetPlayedItems;

@property (nonatomic, readonly) int currentItemIndex;
- (PlaylistItem *)currentItem;
- (PlaylistItem *)moveToNextItem;
- (PlaylistItem *)moveToPrevItem;
- (PlaylistItem *)moveToFirstItem;
- (PlaylistItem *)moveToItemWithIndex:(int)index;
- (void)addCurrentItemToAlreadyPlayedItems;

// used when item from playlist is played from queue
- (void)findAndSetCurrentItemTo:(PlaylistItem *)item;

- (void)cancelID3Reads;

// sorting
@property (nonatomic, strong) NSString *sortedBy;
@property (nonatomic, assign) BOOL sortedAscending;
// used to preserve selected items before and after sorting
- (void)storeIndexes:(NSIndexSet *)indexSet;
- (NSIndexSet *)indexesAfterSorting;

- (BOOL)isQueue;

@end
