//
//  TableSongsDataSource.m
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaylistTableManager.h"
#import "LibManager.h"
#import "Playlist.h"
#import "PlaylistItem.h"
#import "LibraryOutlineViewManager.h"
#import "Player.h"
#import "FilePlayer.h"
#import "PlaylistManager.h"
#import "Tags.h"
#import "TagsUtils.h"
#import "DragDataConverter.h"
#import "NSObject+Observe.h"

@implementation PlaylistTableManager {
  Playlist *dragSourcePlaylist;
}

#pragma mark - init

static PlaylistTableManager *sharedManager = nil;

+ (PlaylistTableManager *)sharedManager {
  return sharedManager;
}

- (void)awakeFromNib {
  sharedManager = self;
  _playlistTable.target = self;
  _playlistTable.doubleAction = @selector(itemDoubleClicked);

  [_playlistTable registerForDraggedTypes:@[kDragTypeTreeNodes, kDragTypePlaylistsRows, kDragTypePlaylistItemsRows]];

  [self observe:kFilePlayerStartedPlayingNotification withAction:@selector(playingItemChanged)];
  [self observe:kFilePlayerStoppedPlayingNotification withAction:@selector(playingItemChanged)];

  _playlist = [PlaylistManager sharedManager].selectedPlaylist;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)itemDoubleClicked {
  [[Player sharedPlayer] playItemWithIndex:(int)_playlistTable.clickedRow];
}

- (void)setPlaylist:(Playlist *)playlist {
  _playlist = playlist;
  sortedColumn = nil;
  [self reloadTable];
  [_playlistTable deselectAll:nil];
}

#pragma mark - drag and drop

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  [pboard declareTypes:@[kDragTypePlaylistItemsRows] owner:nil];
  [pboard setData:[DragDataConverter dataFromArray:rows]
          forType:kDragTypePlaylistItemsRows];
  dragSourcePlaylist = _playlist;
  return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
  return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
  NSString *draggingType = [info.draggingPasteboard.types lastObject];
  NSArray *items = [DragDataConverter arrayFromData:[info.draggingPasteboard dataForType:draggingType]];

  if ([draggingType isEqualToString:kDragTypeTreeNodes]) {

    [_playlist addTreeNodes:items atPos:(int)row];

  } else if ([draggingType isEqualToString:kDragTypePlaylistsRows]) {

    NSMutableArray *arr = [NSMutableArray new];
    for (NSNumber *n in items) [arr addObject:[PlaylistManager sharedManager].playlists[n.intValue]];
    [_playlist addItemsFromPlaylists:arr atPos:(int)row];

  } else if ([draggingType isEqualToString:kDragTypePlaylistItemsRows]) {

    int newPos = (int)row;

    if (dragSourcePlaylist == _playlist) {
      newPos = [_playlist reorderSongs:items atPos:(int)row];
    } else {
      NSMutableArray *arr = [NSMutableArray new];
      for (NSNumber *n in items) [arr addObject:dragSourcePlaylist[n.intValue]];
      [_playlist addPlaylistItems:arr atPos:(int)row];
    }

    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(newPos, items.count)] byExtendingSelection:NO];
  }

  [self reloadTable];
  return YES;
}

- (void)addTreeNodesToPlaylist:(NSArray *)treeNodes {
  [_playlist addTreeNodes:treeNodes atPos:_playlist.numberOfItems];
  [self reloadTable];
}

#pragma mark - delegate

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
  if (sortedColumn == tableColumn) {
    sortAscending = !sortAscending;
    [_playlist reverse];
  } else {
    sortAscending = YES;

    if (sortedColumn) [tableView setIndicatorImage:nil inTableColumn:sortedColumn];
    sortedColumn = tableColumn;

    [tableView setHighlightedTableColumn:tableColumn];
    [_playlist sortBy:tableColumn.identifier];
  }

  [tableView setIndicatorImage:[NSImage imageNamed: sortAscending? @"NSAscendingSortIndicator": @"NSDescendingSortIndicator"] inTableColumn:tableColumn];
  [self reloadTable];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)c forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTextFieldCell *cell = (NSTextFieldCell*)c;

  if (self.showingNowPlayingPlaylist && row == highlightedRow) {
    cell.font = [NSFont boldSystemFontOfSize:13];
  } else {
    cell.font = [NSFont systemFontOfSize:13];
  }
}

#pragma mark - data source

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
  return _playlist.numberOfItems;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  PlaylistItem *item = _playlist[(int)row];
  int tagIndex = [Tags indexFromTagName:tableColumn.identifier];
  NSString *value = [item tagValueForIndex:tagIndex];

  if (item == _playlist.currentItem) {
    highlightedRow = (int)row;
  }

  if ([tableColumn.identifier isEqualToString:@"length"]) {
    int sec = item.lengthInSeconds;
    value = [NSString stringWithFormat:@"%d:%02d", sec/60, sec%60];
  }

  return value;
}

#pragma mark - deleting songs

- (IBAction)deleteItemsPressed:(id)sender {
  [self deleteSelectedItems];
}

- (void)deleteSelectedItems {
  NSIndexSet *selectedIndexes = _playlistTable.selectedRowIndexes;
  int n = (int)_playlistTable.numberOfRows;
  int m = (int)selectedIndexes.count;
  int selectRow = (int)selectedIndexes.lastIndex;

  if (m > 0) {
    [self.playlist removeSongsAtIndexes:selectedIndexes];
    [_playlistTable deselectAll:nil];
    [self reloadTable];

    selectRow = (selectRow < n-1)? selectRow-m+1: n-m-1;

    [_playlistTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectRow] byExtendingSelection:NO];
    [_playlistTable scrollRowToVisible:selectRow];
  }
}

- (void)reloadTable {
  highlightedRow = -1;
  [_playlistTable reloadData];
}

#pragma mark - update now playing

- (void)playingItemChanged {
  if (self.showingNowPlayingPlaylist) [self reloadTable];
}

- (BOOL)showingNowPlayingPlaylist {
  return _playlist == [Player sharedPlayer].nowPlayingPlaylist;
}

@end
