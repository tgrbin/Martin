//
//  LibraryOutlineViewDataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import <Foundation/Foundation.h>

@class PlaylistItem;

@interface LibraryOutlineViewDataSource : NSObject

- (NSString *)nameForItem:(id)item;

- (NSInteger)numberOfChildrenOfItem:(id)item;
- (id)childAtIndex:(NSInteger)index ofItem:(id)item;

- (BOOL)isItemLeaf:(id)item;
- (id)parentOfItem:(id)item;
- (BOOL)isItemFromLibrary:(id)item;

- (void)enumeratePlaylistItemsFromItem:(id)item
                             withBlock:(void (^)(PlaylistItem *playlistItem))block;

@end
