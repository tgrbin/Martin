//
//  TableSongsDataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Playlist;

@interface PlaylistTableManager : NSObject <NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>

@property (nonatomic, strong) Playlist *playlist;

- (void)deleteSelectedItems;
- (void)addTreeNodes:(NSArray *)treeNodes;
- (void)addPlaylistItems:(NSArray *)items;

- (void)queueChanged;
- (void)selectFirstItem;

@end
