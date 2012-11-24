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
  int currentItem; // this is index in playlistItems vector, doesn't correspond with the playlist order
  
  struct PlaylistImpl *impl;
}

@property (nonatomic, strong) NSString *name;

- (id)initWithName:(NSString *)n playlistItems:(NSArray *)s;

- (id)initWithTreeNodes:(NSArray *)arr; // these two method suggest playlist name based on items
- (id)initWithPlaylistItems:(NSArray *)arr;

- (void)addPlaylistItems:(NSArray *)arr;
- (void)addTreeNodes:(NSArray *)treeNodes atPos:(int)pos;
- (void)removeSongsAtIndexes:(NSIndexSet *)indexes;
- (int)reorderSongs:(NSArray *)rows atPos:(int)pos;
- (void)sortBy:(NSString *)str;
- (void)reverse;

- (int)numberOfItems;
- (PlaylistItem *)objectAtIndexedSubscript:(int)index;

- (PlaylistItem *)currentItem;
- (PlaylistItem *)moveToNextItem;
- (PlaylistItem *)moveToPrevItem;
- (PlaylistItem *)moveToFirstItem;
- (PlaylistItem *)moveToItemWithIndex:(int)index;
- (void)forgetCurrentItem;

@end
