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

@implementation PlaylistTableManager

#pragma mark - init

static PlaylistTableManager *sharedManager = nil;

+ (PlaylistTableManager *)sharedManager {
  return sharedManager;
}

- (void)awakeFromNib {
  sharedManager = self;
  _playlistTable.target = self;
  _playlistTable.doubleAction = @selector(itemDoubleClicked);
  [_playlistTable registerForDraggedTypes:@[@"MyDragType"]];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playingItemChanged)
                                               name:kFilePlayerStartedPlayingNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playingItemChanged)
                                               name:kFilePlayerStoppedPlayingNotification
                                             object:nil];

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
  [pboard declareTypes:@[@"MyDragType"] owner:nil];
  [pboard setData:[NSData data] forType:@"MyDragType"];
  _dragRows = rows;
  return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  if (info.draggingSource == [LibraryOutlineViewManager sharedManager].outlineView || info.draggingSource == tableView) {
    [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
    return NSDragOperationCopy;
  } else {
    return NSDragOperationNone;
  }
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
  if (info.draggingSource == [LibraryOutlineViewManager sharedManager].outlineView) {
    [_playlist addTreeNodes:[LibraryOutlineViewManager sharedManager].draggingItems atPos:(int)row];
  } else if (info.draggingSource == tableView) {
    int newPos = [_playlist reorderSongs:_dragRows atPos:(int)row];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(newPos, _dragRows.count)] byExtendingSelection:NO];
  } else {
    return NO;
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
