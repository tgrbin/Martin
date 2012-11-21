//
//  TableSongsDataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MartinAppDelegate;
@class Playlist;
@class PlaylistItem;

@interface TableSongsDataSource : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
  BOOL sortAscending;
  
  NSArray *dragRows;
  
  IBOutlet MartinAppDelegate *appDelegate;
  IBOutlet NSTableView *table;
}

@property (nonatomic, strong) Playlist *playlist;
@property (nonatomic, strong) NSTableColumn *sortedColumn;
@property (nonatomic, assign) BOOL showingNowPlayingPlaylist;

- (void)playingItemChanged;
- (void)deleteSelectedItems;

@end
