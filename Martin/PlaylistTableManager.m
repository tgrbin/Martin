//
//  TableSongsDataSource.m
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaylistTableManager.h"
#import "MartinAppDelegate.h"
#import "LibManager.h"
#import "Playlist.h"
#import "PlaylistItem.h"
#import "Tags.h"
#import "TagsUtils.h"
#import "DragDataConverter.h"
#import "NSObject+Observe.h"
#import "ShortcutBinder.h"
#import "SongsFinder.h"

@implementation PlaylistTableManager {
  BOOL sortAscending;
  int highlightedRow;
  NSTableColumn *sortedColumn;

  Playlist *dragSourcePlaylist;

  IBOutlet NSTableView *playlistTable;
}

#pragma mark - init

- (void)awakeFromNib {
  playlistTable.target = self;
  playlistTable.doubleAction = @selector(itemDoubleClicked);

  [playlistTable registerForDraggedTypes:@[kDragTypeTreeNodes, kDragTypePlaylistsRows, kDragTypePlaylistItemsRows, NSFilenamesPboardType]];

  [self observe:kFilePlayerStartedPlayingNotification withAction:@selector(playingItemChanged)];
  [self observe:kFilePlayerStoppedPlayingNotification withAction:@selector(playingItemChanged)];

  _playlist = [MartinAppDelegate get].playlistManager.selectedPlaylist;

  [ShortcutBinder bindControl:playlistTable andKey:kMartinKeyDelete toTarget:self andAction:@selector(deleteSelectedItems)];
  [ShortcutBinder bindControl:playlistTable andKey:kMartinKeyEnter toTarget:self andAction:@selector(playItemAtSelectedRow)];
  [ShortcutBinder bindControl:playlistTable andKey:kMartinKeyQueueItems toTarget:self andAction:@selector(queueSelectedItems)];
}

#pragma mark - public

- (void)itemDoubleClicked {
  [[MartinAppDelegate get].player playItemWithIndex:(int)playlistTable.clickedRow];
}

- (void)setPlaylist:(Playlist *)playlist {
  _playlist = playlist;
  sortedColumn = nil;
  [self tableChanged];
  [playlistTable deselectAll:nil];
}

- (void)selectFirstItem {
  [playlistTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
             byExtendingSelection:NO];
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
  NSArray *draggingTypes = info.draggingPasteboard.types;

  int endPosition = (int)row;
  int itemsCount = 0;

  if ([draggingTypes containsObject:NSFilenamesPboardType]) {
    NSArray *items = [info.draggingPasteboard propertyListForType:NSFilenamesPboardType];
    NSArray *playlistItems = [SongsFinder playlistItemsFromFolders:items];
    itemsCount = [_playlist addPlaylistItems:playlistItems atPos:endPosition];
  } else {
    NSString *draggingType = [draggingTypes lastObject];
    NSArray *items = [DragDataConverter arrayFromData:[info.draggingPasteboard dataForType:draggingType]];
    if ([draggingType isEqualToString:kDragTypeTreeNodes]) {

      itemsCount = [_playlist addTreeNodes:items atPos:endPosition];

    } else if ([draggingType isEqualToString:kDragTypePlaylistsRows]) {

      NSMutableArray *arr = [NSMutableArray new];
      for (NSNumber *n in items) [arr addObject:[MartinAppDelegate get].playlistManager.playlists[n.intValue]];
      itemsCount = [_playlist addItemsFromPlaylists:arr atPos:endPosition];

    } else if ([draggingType isEqualToString:kDragTypePlaylistItemsRows]) {

      if (dragSourcePlaylist == _playlist) {
        endPosition = [_playlist reorderItemsAtRows:items toPos:endPosition];
      } else {
        NSMutableArray *arr = [NSMutableArray new];
        for (NSNumber *n in items) [arr addObject:dragSourcePlaylist[n.intValue]];
        itemsCount = [_playlist addPlaylistItems:arr atPos:endPosition];
      }
    }
  }

  [self tableChanged];
  [tableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(endPosition, itemsCount)] byExtendingSelection:NO];
  [[MartinAppDelegate get].window makeFirstResponder:tableView];

  return YES;
}

- (void)addTreeNodes:(NSArray *)treeNodes {
  [_playlist addTreeNodes:treeNodes];
  [self tableChanged];
}

- (void)addPlaylistItems:(NSArray *)items {
  [_playlist addPlaylistItems:items];
  [self tableChanged];
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
  [self tableChanged];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)c forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTextFieldCell *cell = (NSTextFieldCell*)c;

  if (self.showingNowPlayingPlaylist && row == highlightedRow) {
    cell.font = [NSFont boldSystemFontOfSize:13];
  } else {
    cell.font = [NSFont systemFontOfSize:13];
  }
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  return NO;
}

#pragma mark - data source

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
  return _playlist.numberOfItems;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  PlaylistItem *item = _playlist[(int)row];
  int tagIndex = [Tags indexFromTagName:tableColumn.identifier];
  NSString *value = [item tagValueForIndex:tagIndex];

  if (self.showingNowPlayingPlaylist && row == _playlist.currentItemIndex) {
    highlightedRow = (int)row;
  }

  if ([tableColumn.identifier isEqualToString:@"length"]) {
    int sec = item.lengthInSeconds;
    value = [NSString stringWithFormat:@"%d:%02d", sec/60, sec%60];
  }

  return value;
}

#pragma mark - actions

- (void)playItemAtSelectedRow {
  [[MartinAppDelegate get].player playItemWithIndex:(int)playlistTable.selectedRow];
}

- (IBAction)deleteItemsPressed:(id)sender {
  [self deleteSelectedItems];
}

- (void)deleteSelectedItems {
  NSIndexSet *selectedIndexes = playlistTable.selectedRowIndexes;
  int n = (int)playlistTable.numberOfRows;
  int m = (int)selectedIndexes.count;
  int selectRow = (int)selectedIndexes.lastIndex;

  if (m > 0) {
    [self.playlist removeSongsAtIndexes:selectedIndexes];
    [playlistTable deselectAll:nil];
    [self tableChanged];

    selectRow = (selectRow < n-1)? selectRow-m+1: n-m-1;

    [playlistTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectRow] byExtendingSelection:NO];
    [playlistTable scrollRowToVisible:selectRow];
  }
}

- (void)queueSelectedItems {
  NSIndexSet *selectedIndexes = playlistTable.selectedRowIndexes;
  NSMutableArray *selectedPlaylistItems = [NSMutableArray new];

  for (NSInteger index = selectedIndexes.firstIndex; index != NSNotFound; index = [selectedIndexes indexGreaterThanIndex:index]) {
    [selectedPlaylistItems addObject:_playlist[(int)index]];
  }

  [[MartinAppDelegate get].playlistManager.queue addPlaylistItems:selectedPlaylistItems];
  [[MartinAppDelegate get].playlistManager reload];
  [self queueChanged];
}

- (void)queueChanged {
  if ([self showingQueuePlaylist]) [self tableChanged];
}

- (void)tableChanged {
  highlightedRow = -1;
  [playlistTable reloadData];
  if ([self showingQueuePlaylist]) {
    [[MartinAppDelegate get].playlistManager reload];
  }
}

- (BOOL)showingQueuePlaylist {
  return _playlist == (Playlist *)[MartinAppDelegate get].playlistManager.queue;
}

#pragma mark - update now playing

- (void)playingItemChanged {
  [self tableChanged];
}

- (BOOL)showingNowPlayingPlaylist {
  return _playlist == [MartinAppDelegate get].player.nowPlayingPlaylist;
}

@end
