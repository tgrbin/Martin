//
//  TableSongsDataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Playlist;

@interface PlaylistTableManager : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
  BOOL sortAscending;
  int highlightedRow;
  NSTableColumn *sortedColumn;
}

+ (PlaylistTableManager *)sharedManager;

@property (nonatomic, strong) Playlist *playlist;
@property (nonatomic, strong) IBOutlet NSTableView *playlistTable;

- (void)deleteSelectedItems;
- (void)addTreeNodesToPlaylist:(NSArray *)treeNodes;

@end
