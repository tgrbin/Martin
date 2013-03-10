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

  [playlistTable registerForDraggedTypes:@[kDragTypeTreeNodes, kDragTypePlaylistsIndexes, kDragTypePlaylistItemsRows, NSFilenamesPboardType]];

  [self observe:kFilePlayerStartedPlayingNotification withAction:@selector(playingItemChanged)];
  [self observe:kFilePlayerStoppedPlayingNotification withAction:@selector(playingItemChanged)];
  [self observe:kLibraryRescanFinishedNotification withAction:@selector(rescanFinished)];

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

- (void)rescanFinished {
  [playlistTable reloadData];
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
  int itemsCount = 0;

  if ([draggingTypes containsObject:NSFilenamesPboardType]) {
    NSArray *items = [info.draggingPasteboard propertyListForType:NSFilenamesPboardType];
    ItemsAndName *itemsAndName = [PlaylistNameGuesser itemsAndNameFromFolders:items];
    itemsCount = [_playlist addPlaylistItems:itemsAndName.items atPos:endPosition];
  } else {
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
  return _playlist == nil? 0: _playlist.numberOfItems;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  PlaylistItem *item = _playlist[(int)row];
  int tagIndex = [Tags indexFromTagName:tableColumn.identifier];
  NSString *value = [item tagValueForIndex:tagIndex];

  if (self.showingNowPlayingPlaylist && row == _playlist.currentItemIndex) {
    highlightedRow = (int)row;
  }

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
  BOOL queueWasEmpty = [MartinAppDelegate get].playlistManager.queue.isEmpty;
  [[MartinAppDelegate get].playlistManager.queue addPlaylistItems:[self selectedPlaylistItems]
                                                     fromPlaylist:_playlist];
  [[MartinAppDelegate get].playlistManager reload];
  [self queueChanged];
  if (queueWasEmpty) [[MartinAppDelegate get].playlistManager queueWillAppear];
}

- (void)queueChanged {
  if ([self showingQueuePlaylist]) [self tableChanged];
}

- (void)tableChanged {
  highlightedRow = -1;
  [playlistTable reloadData];
  if ([self showingQueuePlaylist]) {
    [[MartinAppDelegate get].playlistManager reload];
    if (_playlist.isEmpty) {
      [[MartinAppDelegate get].playlistManager queueWillDisappear];
    }
  }
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

#pragma mark - update now playing

- (void)playingItemChanged {
  [self tableChanged];
}

- (BOOL)showingNowPlayingPlaylist {
  return _playlist == [MartinAppDelegate get].player.nowPlayingPlaylist;
}

@end
