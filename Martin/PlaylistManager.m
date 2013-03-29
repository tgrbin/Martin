//
//  PlaylistManager.m
//  Martin
//
//  Created by Tomislav Grbin on 10/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaylistManager.h"
#import "MartinAppDelegate.h"
#import "Playlist.h"
#import "PlaylistItem.h"
#import "Player.h"
#import "FilePlayer.h"
#import "DefaultsManager.h"
#import "PlaylistPersistence.h"
#import "LibManager.h"
#import "DragDataConverter.h"
#import "NSObject+Observe.h"
#import "ShortcutBinder.h"
#import "PlaylistNameGuesser.h"

static const double dragHoverTime = 1;

@implementation PlaylistManager {
  NSMutableArray *playlists;

  BOOL ignoreSelectionChange;
  NSTimer *dragHoverTimer;
  NSInteger dragHoverRow;

  IBOutlet NSTableView *playlistsTable;
}

- (void)awakeFromNib {
  playlistsTable.target = self;
  playlistsTable.doubleAction = @selector(startPlayingSelectedPlaylist);

  [playlistsTable registerForDraggedTypes:@[kDragTypeTreeNodes, kDragTypePlaylistsIndexes, kDragTypePlaylistItemsRows, NSFilenamesPboardType]];

  [self selectRow:[[DefaultsManager objectForKey:kDefaultsKeySelectedPlaylistIndex] intValue]];
  [self updateSelectedPlaylist];

  [self observe:kFilePlayerEventNotification withAction:@selector(handlePlayerEvent)];

  [self bindShortcuts];
}

- (id)init {
  if (self = [super init]) {
    [LibManager initLibrary];

    _shuffle = [[DefaultsManager objectForKey:kDefaultsKeyShuffle] boolValue];
    _repeat = [[DefaultsManager objectForKey:kDefaultsKeyRepeat] boolValue];
    playlists = [NSMutableArray arrayWithArray:[PlaylistPersistence loadPlaylists]];
  }

  return self;
}

- (void)bindShortcuts {
  NSDictionary *bindings = @{
                             @(kMartinKeyDelete): @"deleteSelectedPlaylists",
                             @(kMartinKeyCmdDown): @"startPlayingSelectedPlaylist",
                             @(kMartinKeyQueueItems): @"queueSelectedPlaylists",
                             @(kMartinKeyRight): @"focusPlaylist"
  };

  [ShortcutBinder bindControl:playlistsTable toTarget:self withBindings:bindings];
}

- (NSArray *)playlistsAtIndexes:(NSArray *)indexes {
  NSMutableArray *arr = [NSMutableArray new];
  for (NSNumber *n in indexes) [arr addObject:playlists[n.intValue]];
  return arr;
}

- (QueuePlaylist *)queue {
  return playlists[0];
}

- (void)queueWillAppear {
  ignoreSelectionChange = YES;
  [playlistsTable selectRowIndexes:[self offsetSelectedRowsBy:1]
              byExtendingSelection:NO];
  ignoreSelectionChange = NO;
}

- (void)queueWillDisappear {
  ignoreSelectionChange = YES;
  [playlistsTable selectRowIndexes:[self offsetSelectedRowsBy:-1]
              byExtendingSelection:NO];
  ignoreSelectionChange = NO;
  [self updateSelectedPlaylist];
}

- (NSIndexSet *)offsetSelectedRowsBy:(int)offset {
  NSIndexSet *is = [playlistsTable selectedRowIndexes];
  NSMutableIndexSet *offsetIs = [NSMutableIndexSet new];
  for (NSInteger i = is.firstIndex; i != NSNotFound; i = [is indexGreaterThanIndex:i])
    if (i+offset >= 0) [offsetIs addIndex:i+offset];
  return offsetIs;
}

- (void)reload {
  [playlistsTable reloadData];
}

- (void)setShuffle:(BOOL)shuffle {
  _shuffle = shuffle;
  [DefaultsManager setObject:@(_shuffle) forKey:kDefaultsKeyShuffle];
}

- (void)setRepeat:(BOOL)repeat {
  _repeat = repeat;
  [DefaultsManager setObject:@(_repeat) forKey:kDefaultsKeyRepeat];
}

- (void)savePlaylists {
  [PlaylistPersistence savePlaylists:playlists];
  [DefaultsManager setObject:@(playlistsTable.selectedRow) forKey:kDefaultsKeySelectedPlaylistIndex];
}

- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes andName:(NSString *)name {
  [self addPlaylist:[[Playlist alloc] initWithName:name andTreeNodes:nodes]];
}

- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes {
  [self addPlaylist:[[Playlist alloc] initWithTreeNodes:nodes]];
}

- (void)addNewPlaylistWithPlaylistItems:(NSArray *)items {
  [self addPlaylist:[[Playlist alloc] initWithPlaylistItems:items]];
}

- (void)addNewPlaylistWithPlaylistItems:(NSArray *)items andName:(NSString *)name {
  [self addPlaylist:[[Playlist alloc] initWithName:name andPlaylistItems:items]];
}

- (void)addPlaylist:(Playlist *)p {
  [playlists addObject:p];
  [playlistsTable reloadData];
  [self selectRow:[self numberOfRows]-1];
  [self updateSelectedPlaylist];
}

- (void)selectRow:(NSInteger)row {
  [playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

- (void)updateSelectedPlaylist {
  if ([self numberOfRows] == 0) {
    _selectedPlaylist = nil;
  } else {
    _selectedPlaylist = [self playlistAtRow:playlistsTable.selectedRow];
  }
  [MartinAppDelegate get].playlistTableManager.playlist = _selectedPlaylist;
}

- (void)handlePlayerEvent {
  [playlistsTable reloadData];
}

- (void)deleteSelectedPlaylists {
  NSMutableIndexSet *is = [[NSMutableIndexSet alloc] initWithIndexSet:playlistsTable.selectedRowIndexes];
  if (is.count == 0) return;

  NSInteger rowToSelect = playlistsTable.selectedRow;
  rowToSelect -= [is countOfIndexesInRange:NSMakeRange(0, rowToSelect)];

  if (self.queue.isEmpty) { // if queue is not visible indexes need to be adjusted
    NSMutableIndexSet *increased = [NSMutableIndexSet new];
    for (NSInteger index = [is firstIndex]; index != NSNotFound; index = [is indexGreaterThanIndex:index]) [increased addIndex:index+1];
    is = increased;
  }

  for (NSInteger index = [is firstIndex]; index != NSNotFound; index = [is indexGreaterThanIndex:index]) {
    [playlists[index] cancelID3Reads];
    [self.queue willRemovePlaylist:playlists[index]];
  }

  if (self.queue.isEmpty == NO && [is containsIndex:0]) {
    [self.queue clear];
    [is removeIndex:0];
  }

  [playlists removeObjectsAtIndexes:is];
  [playlistsTable reloadData];

  [self selectRow:MAX(0, MIN(rowToSelect, [self numberOfRows]-1))];
  [self updateSelectedPlaylist];
}

- (void)startPlayingSelectedPlaylist {
  NSInteger row = playlistsTable.clickedRow;
  if (row == -1) row = playlistsTable.selectedRow;

  [self selectRow:row];
  [[MartinAppDelegate get].player playSelectedPlaylist];
}

- (void)queueSelectedPlaylists {
  [self.queue addItemsFromPlaylists:[self selectedPlaylists]
                              atPos:self.queue.numberOfItems];
}

- (void)takeFocus {
  [[MartinAppDelegate get].window makeFirstResponder:playlistsTable];
}

- (void)focusPlaylist {
  [[MartinAppDelegate get].playlistTableManager takeFocus];
}

#pragma mark - context menu actions

- (IBAction)deletePlaylistPressed:(id)sender {
  [self deleteSelectedPlaylists];
}

- (IBAction)addPlaylistPressed:(id)sender {
  Playlist *p = [Playlist new];
  if (playlistsTable.clickedRow != -1) {
    [p addItemsFromPlaylists:[self selectedPlaylists] atPos:0];
  }
  [self addPlaylist:p];

  [playlistsTable editColumn:0
                         row:playlistsTable.numberOfRows-1
                   withEvent:nil
                      select:YES];
}

- (IBAction)sortPlaylists:(id)sender {
  [playlists sortUsingComparator:^NSComparisonResult(Playlist *p1, Playlist *p2) {
    if (p1 == self.queue) return NSOrderedAscending;
    if (p2 == self.queue) return NSOrderedDescending;
    return [p1.name compare:p2.name];
  }];
  [self reload];
}

- (IBAction)renamePlaylist:(id)sender {
  [playlistsTable editColumn:0
                         row:playlistsTable.clickedRow
                   withEvent:nil
                      select:YES];
}

- (IBAction)queuePlaylists:(id)sender {
  [self queueSelectedPlaylists];
}

- (IBAction)playPlaylist:(id)sender {
  [self startPlayingSelectedPlaylist];
}

- (NSArray *)selectedPlaylists {
  NSMutableArray *arr = [NSMutableArray new];
  NSIndexSet *is = playlistsTable.selectedRowIndexes;
  for (NSInteger i = [is firstIndex]; i != NSNotFound; i = [is indexGreaterThanIndex:i]) [arr addObject:[self playlistAtRow:i]];
  return arr;
}

#pragma mark - drag and drop

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  if (self.queue.isEmpty) {
    NSMutableArray *increasedRows = [NSMutableArray new];
    for (NSNumber *n in rows) [increasedRows addObject:@(n.intValue+1)];
    rows = increasedRows;
  }
  [pboard declareTypes:@[kDragTypePlaylistsIndexes] owner:nil];
  [pboard setData:[DragDataConverter dataFromArray:rows]
          forType:kDragTypePlaylistsIndexes];
  return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  [self resetDragHoverTimer];

  // can't drag queue within playlists table
  if (self.queue.isEmpty == NO) {
    NSString *draggingType = [info.draggingPasteboard.types lastObject];
    if ([draggingType isEqualToString:kDragTypePlaylistsIndexes]) {
      NSArray *items = [DragDataConverter arrayFromData:[info.draggingPasteboard dataForType:draggingType]];
      if (items.count == 1 && [items[0] intValue] == 0) return NSDragOperationNone;
    }
  }

  if (dropOperation == NSTableViewDropOn) {
    dragHoverRow = row;
    [self setDragHoverTimer];
  }

  // can't drop anything above the queue
  if (self.queue.isEmpty == NO && dropOperation == NSTableViewDropAbove && row == 0) return NSDragOperationNone;

  return NSDragOperationCopy;
}

- (void)setDragHoverTimer {
  dragHoverTimer = [NSTimer scheduledTimerWithTimeInterval:dragHoverTime
                                                    target:self
                                                  selector:@selector(dragHovered)
                                                  userInfo:nil
                                                   repeats:NO];
}

- (void)dragHovered {
  [self resetDragHoverTimer];
  [self selectRow:dragHoverRow];
}

- (void)dragExited {
  [self resetDragHoverTimer];
}

- (void)resetDragHoverTimer {
  [dragHoverTimer invalidate];
  dragHoverTimer = nil;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
  NSArray *draggingTypes = info.draggingPasteboard.types;

  NSInteger actualRow = row;
  if (self.queue.isEmpty) ++row;

  if ([draggingTypes containsObject:NSFilenamesPboardType]) {
    NSArray *items = [info.draggingPasteboard propertyListForType:NSFilenamesPboardType];
    [PlaylistNameGuesser itemsAndNameFromFolders:items withBlock:^(NSArray *items, NSString *name) {
      if (items.count > 0) {
        if (dropOperation == NSTableViewDropAbove) {
          Playlist *p = [[Playlist alloc] initWithName:name andPlaylistItems:items];
          [playlists insertObject:p atIndex:row];
          [tableView reloadData];
        } else {
          Playlist *p = playlists[row];
          [p addPlaylistItems:items];
        }
        [self selectRow:actualRow];
        [self updateSelectedPlaylist];
        [[MartinAppDelegate get].window makeFirstResponder:playlistsTable];
      }
    }];
  } else {
    NSString *draggingType = [draggingTypes lastObject];
    NSArray *items = [DragDataConverter arrayFromData:[info.draggingPasteboard dataForType:draggingType]];

    if ([draggingType isEqualToString:kDragTypePlaylistsIndexes]) {
      if (dropOperation == NSTableViewDropAbove) {
        [self relocateRows:items toPos:row];
      } else {
        Playlist *destPlaylist = playlists[row];
        for (NSNumber *n in items) {
          [destPlaylist addItemsFromPlaylist:playlists[n.intValue]];
        }
        [self selectRow:actualRow];
      }
    } else {
      BOOL fromLibrary = [draggingType isEqualToString:kDragTypeTreeNodes];

      if (fromLibrary == NO) {
        NSMutableArray *arr = [NSMutableArray new];
        for (NSNumber *row in items) [arr addObject:_selectedPlaylist[row.intValue]];
        items = arr;
      }

      if (dropOperation == NSTableViewDropAbove) {
        Playlist *p;
        if (fromLibrary) p = [[Playlist alloc] initWithTreeNodes:items];
        else p = [[Playlist alloc] initWithPlaylistItems:items];

        [playlists insertObject:p atIndex:row];
        [tableView reloadData];
      } else {
        Playlist *p = playlists[row];
        if (fromLibrary) [p addTreeNodes:items atPos:p.numberOfItems];
        else [p addPlaylistItems:items];
      }
      [self selectRow:actualRow];
      [self updateSelectedPlaylist];
    }
    [[MartinAppDelegate get].window makeFirstResponder:playlistsTable];
  }

  return YES;
}

- (void)relocateRows:(NSArray *)rows toPos:(NSInteger)pos {
  NSMutableIndexSet *rowsToRelocate = [NSMutableIndexSet new];
  NSMutableArray *objectsToRelocate = [NSMutableArray new];
  NSInteger dest = pos;
  for (NSNumber *n in rows) {
    int i = n.intValue;
    if (i > 0) {
      [objectsToRelocate addObject:playlists[i]];
      [rowsToRelocate addIndex:i];
      if (i < pos) --dest;
    }
  };

  NSIndexSet *destIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(dest, rowsToRelocate.count)];
  NSIndexSet *actualIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(dest-self.queue.isEmpty, rowsToRelocate.count)];
  [playlists removeObjectsAtIndexes:rowsToRelocate];
  [playlists insertObjects:objectsToRelocate atIndexes:destIndexSet];
  [playlistsTable reloadData];
  ignoreSelectionChange = YES;
  [playlistsTable selectRowIndexes:actualIndexSet byExtendingSelection:NO];
  ignoreSelectionChange = NO;
}

#pragma mark - table data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [self numberOfRows];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  Playlist *p = [self playlistAtRow:row];
  if (p == self.queue) return [NSString stringWithFormat:@"%@ (%d)", p.name, p.numberOfItems];
  else return p.name;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  Playlist *p = [self playlistAtRow:row];
  NSString *newName = (NSString *)object;
  p.name = [newName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

#pragma mark - table delegate

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  // cant rename queue playlist
  if (row == 0 && self.queue.isEmpty == NO) return NO;

  NSEvent *e = [NSApp currentEvent];
  if (e.type == NSKeyDown && e.keyCode == 48) return NO;
  return YES;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)c forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTextFieldCell *cell = (NSTextFieldCell*)c;
  BOOL playingThisPlaylist = [[MartinAppDelegate get].player nowPlayingItemFromPlaylist:[self playlistAtRow:row]];
  cell.font = playingThisPlaylist? [NSFont boldSystemFontOfSize:13]: [NSFont systemFontOfSize:13];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
  if (ignoreSelectionChange == NO) {
    [self updateSelectedPlaylist];
  }
}

- (NSInteger)numberOfRows {
  return playlists.count - (self.queue.isEmpty == YES);
}

- (Playlist *)playlistAtRow:(NSInteger)index {
  if (self.queue.isEmpty) ++index;
  return playlists[index];
}

#pragma mark - menu delegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
  int n = (int)menu.numberOfItems;
  if (playlistsTable.clickedRow == -1) {
    for (int i = 0; i < n-2; ++i) [menu itemAtIndex:i].enabled = NO;
  } else {
    for (int i = 0; i < n-2; ++i) [menu itemAtIndex:i].enabled = YES;

    if (playlistsTable.selectedRowIndexes.count > 1) {
      [menu itemWithTitle:@"Rename"].enabled = NO;
      [menu itemWithTitle:@"Duplicate"].enabled = NO;
    }
  }
}

@end
