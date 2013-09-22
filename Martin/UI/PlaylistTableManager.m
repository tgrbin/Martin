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
  [self centerTableToCurrentItem];
  [self bindShortcuts];
  [self initTableHeaderViewMenu];
}

- (void)bindShortcuts {
  NSDictionary *bindings =
  @{
    @(kMartinKeyDelete): @"deleteSelectedItems:",
    @(kMartinKeyEnter): @"playItemAtSelectedRow",
    @(kMartinKeyQueueItems): @"queueSelectedItems:",
    @(kMartinKeyCmdEnter): @"createNewPlaylistWithSelectedItems:",
    @(kMartinKeySelectAll): @"selectAllItems:",
    @(kMartinKeySelectAlbum): @"selectAlbum:",
    @(kMartinKeySelectArtist): @"selectArtist:",
    @(kMartinKeyLeft): @"focusPlaylists",
    @(kMartinKeyCrop): @"cropSelectedItems:",
    @(kMartinKeyShuffle): @"shuffleSelectedItems:",
    @(kMartinKeyPlayPause): @"playOrPausePressed"
  };

  [ShortcutBinder bindControl:playlistTable toTarget:self withBindings:bindings];

  [ShortcutBinder bindControl:playlistTable andKey:kMartinKeyPlayPause toTarget:[MartinAppDelegate get].player andAction:@selector(playOrPause)];
}

- (void)reloadTableData {
  [playlistTable reloadData];
}

#pragma mark - public

- (void)itemDoubleClicked {
  if (playlistTable.clickedRow == -1) return;
  [[MartinAppDelegate get].player playItemWithIndex:(int)playlistTable.clickedRow];
}

- (void)setPlaylist:(Playlist *)playlist {
  _playlist = playlist;
  [playlistTable reloadData];
  [self centerTableToCurrentItem];
  [self updateSortIndicator];
  [playlistTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_playlist.currentItemIndex]
             byExtendingSelection:NO];
}

- (void)selectFirstItem {
  [playlistTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
             byExtendingSelection:NO];
}

#pragma mark - menu delegate

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
  _dragSourcePlaylist = _playlist;
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
    NSInteger itemsCount = 0;

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

      if (_dragSourcePlaylist == _playlist) {
        itemsCount = items.count;
        endPosition = [_playlist reorderItemsAtRows:items toPos:endPosition];
      } else {
        NSMutableArray *arr = [NSMutableArray new];
        for (NSNumber *n in items) [arr addObject:_dragSourcePlaylist[n.intValue]];
        itemsCount = [_playlist addPlaylistItems:arr atPos:endPosition fromPlaylist:_dragSourcePlaylist];
      }
    }

    [self playlistChanged];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(endPosition, itemsCount)] byExtendingSelection:NO];
    [[MartinAppDelegate get].window makeFirstResponder:tableView];
  }

  return YES;
}

- (void)addTreeNodes:(NSArray *)treeNodes {
  [self addedItemsToEndOfPlaylist:[_playlist addTreeNodes:treeNodes]];
}

- (void)addPlaylistItems:(NSArray *)items {
  [self addedItemsToEndOfPlaylist:[_playlist addPlaylistItems:items]];
}

- (void)addedItemsToEndOfPlaylist:(int)count {
  NSIndexSet *addedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_playlist.numberOfItems - count, count)];
  [playlistTable selectRowIndexes:addedIndexes byExtendingSelection:NO];
  [playlistTable scrollRowToVisible:_playlist.numberOfItems - 1];
  [self playlistChanged];
}

#pragma mark - table delegate and data source

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
  BOOL nowPlaying = [[MartinAppDelegate get].player nowPlayingItemFromPlaylist:_playlist];

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

#pragma mark - actions

- (IBAction)createNewPlaylistWithSelectedItems:(id)sender {
  [[MartinAppDelegate get].playlistManager addNewPlaylistWithPlaylistItems:[self chosenItems]];
}

- (IBAction)queueSelectedItems:(id)sender {
  NSArray *arr = [self chosenItems];
  if (arr.count > 0) {
    [[MartinAppDelegate get].tabsManager.queue addPlaylistItems:arr
                                                   fromPlaylist:_playlist];
  }
}

- (IBAction)cropSelectedItems:(id)sender {
  NSIndexSet *indexes = [self chosenIndexes];
  NSMutableIndexSet *cropped = [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, _playlist.numberOfItems)];
  [cropped removeIndexes:indexes];

  if (cropped.count > 0) {
    [_playlist removeSongsAtIndexes:cropped];
    [playlistTable deselectAll:nil];
    [self playlistChanged];
  }
}

- (IBAction)shuffleSelectedItems:(id)sender {
  [_playlist shuffleIndexes:[self chosenIndexes]];
  [self playlistChanged];
}

- (void)playItemAtSelectedRow {
  [[MartinAppDelegate get].player playItemWithIndex:(int)playlistTable.selectedRow];
}

- (IBAction)deleteSelectedItems:(id)sender {
  NSIndexSet *indexes = [self chosenIndexes];
  NSInteger n = _playlist.numberOfItems;
  NSInteger m = indexes.count;
  NSInteger selectRow = indexes.lastIndex;

  if (m > 0) {
    [_playlist removeSongsAtIndexes:indexes];
    [playlistTable deselectAll:nil];
    [self playlistChanged];

    selectRow = (selectRow < n-1)? selectRow-m+1: n-m-1;

    [playlistTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectRow] byExtendingSelection:NO];
    [playlistTable scrollRowToVisible:selectRow];
  }
}

- (IBAction)showInFinder:(id)sender {
  NSArray *items = [self chosenItems];
  NSMutableArray *paths = [NSMutableArray new];
  for (PlaylistItem *pi in items) [paths addObject:pi.filename];

  NSMutableArray *urls = [NSMutableArray new];
  for (NSString *path in paths) [urls addObject:[NSURL fileURLWithPath:path]];
  [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
}

- (NSArray *)chosenItems {
  NSInteger clickedRow = playlistTable.clickedRow;
  NSIndexSet *selectedRows = playlistTable.selectedRowIndexes;
  NSMutableArray *items = [NSMutableArray new];

  if (clickedRow == -1 || [selectedRows containsIndex:clickedRow]) {
    for (NSUInteger row = selectedRows.firstIndex; row != NSNotFound; row = [selectedRows indexGreaterThanIndex:row]) {
      [items addObject:_playlist[(int)row]];
    }
  } else {
    [items addObject:_playlist[(int)clickedRow]];
  }

  return items;
}

- (NSIndexSet *)chosenIndexes {
  if (playlistTable.clickedRow != -1 && [playlistTable.selectedRowIndexes containsIndex:playlistTable.clickedRow] == NO) {
    return [NSIndexSet indexSetWithIndex:playlistTable.clickedRow];
  }
  return playlistTable.selectedRowIndexes;
}

#pragma mark - focus changes

- (void)focusPlaylists {
  [[MartinAppDelegate get].playlistManager takeFocus];
}

- (void)takeFocus {
  [[MartinAppDelegate get].window makeFirstResponder:playlistTable];
}

- (IBAction)takeFocus:(id)sender {
  [self takeFocus];
}

#pragma mark - select items actions

- (IBAction)selectAllItems:(id)sender {
  [playlistTable selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _playlist.numberOfItems)]
             byExtendingSelection:NO];
}

- (IBAction)selectArtist:(id)sender {
  [self selectItemsWithTagIndex:kTagIndexArtist];
}

- (IBAction)selectAlbum:(id)sender {
  [self selectItemsWithTagIndex:kTagIndexAlbum];
}

- (void)selectItemsWithTagIndex:(TagIndex)tagIndex {
  NSSet *values = [self valuesForTagWithIndex:tagIndex fromItems:[self chosenItems]];
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

#pragma mark - other

- (void)centerTableToCurrentItem {
  int row = _playlist.currentItemIndex;

  [playlistTable scrollPoint:CGPointZero];
  if (row >= 0) {
    int n = playlistTable.superview.frame.size.height / playlistTable.rowHeight;
    [playlistTable scrollRowToVisible:MIN(row + n/2, _playlist.numberOfItems-1)];
  }
}

- (void)queueChanged {
  if ([MartinAppDelegate get].tabsManager.queue.isEmpty) {
    [[MartinAppDelegate get].tabsManager hideQueueTab];
  } else {
    [[MartinAppDelegate get].tabsManager showQueueTab];
  }

  [[MartinAppDelegate get].tabsManager refreshQueueObjectCount];
}

- (void)playlistChanged {
  [playlistTable reloadData];
  if ([self showingQueuePlaylist]) {
    [self queueChanged];
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
  return _playlist == [MartinAppDelegate get].tabsManager.queue;
}

@end
