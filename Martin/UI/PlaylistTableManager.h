//
//  TableSongsDataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//

#import <Foundation/Foundation.h>

@class Playlist;

@interface PlaylistTableManager : NSObject <NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>

@property (nonatomic, strong) Playlist *playlist;
@property (nonatomic, strong) Playlist *dragSourcePlaylist;

- (void)addTreeNodes:(NSArray *)treeNodes;
- (void)addPlaylistItems:(NSArray *)items;

- (void)queueChanged;
- (void)selectFirstItem;

- (void)reloadTableData;

@end
