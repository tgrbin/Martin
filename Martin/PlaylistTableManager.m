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
#import "RescanState.h"
#import "PlaylistNameGuesser.h"

@implementation PlaylistTableManager {
  Playlist *dragSourcePlaylist;

  IBOutlet NSTableView *playlistTable;
}

#pragma mark - init

- (void)awakeFromNib {
  playlistTable.target = self;
  playlistTable.doubleAction = @selector(itemDoubleClicked);

  [playlistTable registerForDraggedTypes:@[kDragTypeTreeNodes, kDragTypePlaylistsIndexes, kDragTypePlaylistItemsRows, NSFilenamesPboardType]];

  [self observe:kFilePlayerEventNotification withAction:@selector(playlistChanged)];
  [self observe:kPlaylistCurrentItemChanged withAction:@selector(playlistChanged)];
  [self observe:kLibraryRescanFinishedNotification withAction:@selector(reloadTableData)];

  _playlist = [MartinAppDelegate get].playlistManager.selectedPlaylist;

  [self bindShortcuts];
  [self initTableHeaderViewMenu];
}

- (void)bindShortcuts {
  NSDictionary *bindings =
  @{
    @(kMartinKeyDelete): @"deleteSelectedItems",
    @(kMartinKeyEnter): @"playItemAtSelectedRow",
    @(kMartinKeyQueueItems): @"queueSelectedItems",
    @(kMartinKeyCmdEnter): @"createNewPlaylistWithSelectedItems",
    @(kMartinKeySelectAll): @"selectAllItems",
    @(kMartinKeySelectAlbum): @"selectAlbum",
    @(kMartinKeySelectArtist): @"selectArtist"
  };

  [bindings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [ShortcutBinder bindControl:playlistTable
                         andKey:[key intValue]
                       toTarget:self
                      andAction:NSSelectorFromString(obj)];
  }];
}

- (void)reloadTableData {
  [playlistTable reloadData];
}

#pragma mark - public

- (void)itemDoubleClicked {
  int clickedRow = (int)playlistTable.clickedRow;
  if (clickedRow == -1) return;
  [[MartinAppDelegate get].player playItemWithIndex:clickedRow];
}

- (void)setPlaylist:(Playlist *)playlist {
  _playlist = playlist;
  [self playlistChanged];
  [self updateSortIndicator];
  [playlistTable deselectAll:nil];
}

- (void)selectFirstItem {
  [playlistTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
             byExtendingSelection:NO];
}

#pragma mark - show and hide columns

- (void)initTableHeaderViewMenu {
  NSMenu *menu = playlistTable.headerView.menu;

  for (NSTableColumn *col in playlistTable.tableColumns) {
    if ([col.identifier isEqualToString:@"title"]) {
      continue;
    }

    NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:[col.headerCell stringValue]
                                                action:@selector(toggleColumn:)
                                         keyEquivalent:@""];
    mi.target = self;
    mi.representedObject = col;
    [menu addItem:mi];
  }
}

- (void)toggleColumn:(id)sender {
  NSTableColumn *col = [sender representedObject];
  [col setHidden:![col isHidden]];
}

- (void)menuWillOpen:(NSMenu *)menu {
  for (NSMenuItem *mi in menu.itemArray) {
    NSTableColumn *col = [mi representedObject];
    [mi setState:col.isHidden? NSOffState: NSOnState];
  }
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

  if ([draggingTypes containsObject:NSFilenamesPboardType]) {
    NSArray *items = [info.draggingPasteboard propertyListForType:NSFilenamesPboardType];
    [PlaylistNameGuesser itemsAndNameFromFolders:items withBlock:^(NSArray *items, NSString *name) {
      int c = [_playlist addPlaylistItems:items atPos:endPosition];
      [self playlistChanged];
      [tableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(endPosition, c)] byExtendingSelection:NO];
      [[MartinAppDelegate get].window makeFirstResponder:tableView];
    }];
  } else {
    int itemsCount = 0;

    NSString *draggingType = [draggingTypes lastObject];
    NSArray *items = [DragDataConverter arrayFromData:[info.draggingPasteboard dataForType:draggingType]];
    if ([draggingType isEqualToString:kDragTypeTreeNodes]) {

      if (_playlist == nil) {
        [[MartinAppDelegate get].playlistManager addNewPlaylistWithTreeNodes:items];
        itemsCount = _playlist.numberOfItems;
      } else {
        itemsCount = [_playlist addTreeNodes:items atPos:endPosition];
      }

    } else if ([draggingType isEqualToString:kDragTypePlaylistsIndexes]) {

      itemsCount = [_playlist addItemsFromPlaylists:[[MartinAppDelegate get].playlistManager playlistsAtIndexes:items]
                                              atPos:endPosition];

    } else if ([draggingType isEqualToString:kDragTypePlaylistItemsRows]) {

      if (dragSourcePlaylist == _playlist) {
        endPosition = [_playlist reorderItemsAtRows:items toPos:endPosition];
      } else {
        NSMutableArray *arr = [NSMutableArray new];
        for (NSNumber *n in items) [arr addObject:dragSourcePlaylist[n.intValue]];
        itemsCount = [_playlist addPlaylistItems:arr atPos:endPosition fromPlaylist:dragSourcePlaylist];
      }
    }

    [self playlistChanged];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(endPosition, itemsCount)] byExtendingSelection:NO];
    [[MartinAppDelegate get].window makeFirstResponder:tableView];
  }

  return YES;
}

- (void)addTreeNodes:(NSArray *)treeNodes {
  [_playlist addTreeNodes:treeNodes];
  [self playlistChanged];
}

- (void)addPlaylistItems:(NSArray *)items {
  [_playlist addPlaylistItems:items];
  [self playlistChanged];
}

#pragma mark - delegate

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
  [_playlist storeIndexes:[playlistTable selectedRowIndexes]];
  [_playlist sortBy:tableColumn.identifier];
  playlistTable.highlightedTableColumn = tableColumn;
  [playlistTable selectRowIndexes:[_playlist indexesAfterSorting] byExtendingSelection:NO];
  [self playlistChanged];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)c forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTextFieldCell *cell = (NSTextFieldCell*)c;

  BOOL atCurrentItem = (row == _playlist.currentItemIndex);
  BOOL nowPlaying = [[MartinAppDelegate get].player playingFromPlaylist:_playlist];

  BOOL altBkg = atCurrentItem;
  BOOL bold = atCurrentItem && nowPlaying;
  cell.font = bold? [NSFont boldSystemFontOfSize:13]: [NSFont systemFontOfSize:13];
  cell.backgroundColor = altBkg? [NSColor colorWithCalibratedWhite:0.7 alpha:1]: [NSColor clearColor];
  cell.drawsBackground = altBkg;

  static BOOL selectedCurrentItemOnRun = NO;
  if (selectedCurrentItemOnRun == NO && atCurrentItem) {
    [playlistTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    selectedCurrentItemOnRun = YES;
  }
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  return NO;
}

#pragma mark - data source

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
  return _playlist == nil? 0: _playlist.numberOfItems;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  PlaylistItem *item = _playlist[(int)row];
  int tagIndex = [Tags indexFromTagName:tableColumn.identifier];
  NSString *value = [item tagValueForIndex:tagIndex];

  if ([tableColumn.identifier isEqualToString:@"title"] && value.length == 0) {
    value = [item.filename lastPathComponent];
  }

  if ([tableColumn.identifier isEqualToString:@"length"]) {
    int sec = item.lengthInSeconds;
    value = [NSString stringWithFormat:@"%d:%02d", sec/60, sec%60];
  }

  return value;
}

#pragma mark - select items actions

- (void)selectAllItems {
  [playlistTable selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _playlist.numberOfItems)]
             byExtendingSelection:NO];
}

- (void)selectAlbum {
  [self selectItemsWithTagIndex:kTagIndexAlbum];
}

- (void)selectArtist {
  [self selectItemsWithTagIndex:kTagIndexArtist];
}

- (void)selectItemsWithTagIndex:(TagIndex)tagIndex {
  NSSet *values = [self valuesForTagWithIndex:tagIndex fromItems:[self selectedPlaylistItems]];
  NSMutableIndexSet *itemsToSelect = [NSMutableIndexSet new];
  for (int i = 0; i < _playlist.numberOfItems; ++i) {
    PlaylistItem *item = _playlist[i];
    NSString *val = [[item tagValueForIndex:tagIndex] lowercaseString];
    if ([values containsObject:val]) {
      [itemsToSelect addIndex:i];
    }
  }

  [playlistTable selectRowIndexes:itemsToSelect
             byExtendingSelection:NO];
}

- (NSSet *)valuesForTagWithIndex:(TagIndex)tagIndex fromItems:(NSArray *)items {
  NSMutableSet *s = [NSMutableSet new];
  for (PlaylistItem *item in items) {
    NSString *val = [[item tagValueForIndex:tagIndex] lowercaseString];
    [s addObject:val];
  }
  return s;
}

#pragma mark - actions

- (void)createNewPlaylistWithSelectedItems {
  [[MartinAppDelegate get].playlistManager addNewPlaylistWithPlaylistItems:[self selectedPlaylistItems]];
}

- (void)playItemAtSelectedRow {
  [[MartinAppDelegate get].player playItemWithIndex:(int)playlistTable.selectedRow];
}

- (void)deleteSelectedItems {
  NSIndexSet *selectedIndexes = playlistTable.selectedRowIndexes;
  int n = (int)playlistTable.numberOfRows;
  int m = (int)selectedIndexes.count;
  int selectRow = (int)selectedIndexes.lastIndex;

  if (m > 0) {
    [self.playlist removeSongsAtIndexes:selectedIndexes];
    [playlistTable deselectAll:nil];
    [self playlistChanged];

    selectRow = (selectRow < n-1)? selectRow-m+1: n-m-1;

    [playlistTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectRow] byExtendingSelection:NO];
    [playlistTable scrollRowToVisible:selectRow];
  }
}

- (void)queueSelectedItems {
  [[MartinAppDelegate get].playlistManager.queue addPlaylistItems:[self selectedPlaylistItems]
                                                     fromPlaylist:_playlist];
}

#pragma mark - other

- (void)queueChanged {
  if ([self showingQueuePlaylist]) [self playlistChanged];
}

- (void)playlistChanged {
  [playlistTable reloadData];
  if ([self showingQueuePlaylist]) {
    [[MartinAppDelegate get].playlistManager reload];
    if (_playlist.isEmpty) {
      [[MartinAppDelegate get].playlistManager queueWillDisappear];
    }
  }

  [self updateSortIndicator];
}

- (void)updateSortIndicator {
  for (NSTableColumn *col in playlistTable.tableColumns) {
    [playlistTable setIndicatorImage:nil inTableColumn:col];
  }
  playlistTable.highlightedTableColumn = nil;

  if (_playlist == nil || _playlist.sortedBy == nil) return;

  NSImage *indicatorImage = [NSImage imageNamed:_playlist.sortedAscending? @"NSAscendingSortIndicator": @"NSDescendingSortIndicator"];
  NSTableColumn *tableColumn = [playlistTable tableColumnWithIdentifier:_playlist.sortedBy];
  [playlistTable setIndicatorImage:indicatorImage
                     inTableColumn:tableColumn];
  playlistTable.highlightedTableColumn = tableColumn;
}

- (BOOL)showingQueuePlaylist {
  return _playlist == [MartinAppDelegate get].playlistManager.queue;
}

- (NSArray *)selectedPlaylistItems {
  NSIndexSet *selectedIndexes = playlistTable.selectedRowIndexes;
  NSMutableArray *items = [NSMutableArray new];
  for (NSInteger index = selectedIndexes.firstIndex; index != NSNotFound; index = [selectedIndexes indexGreaterThanIndex:index]) {
    [items addObject:_playlist[(int)index]];
  }
  return items;
}

@end
