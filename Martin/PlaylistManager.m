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
#import "SongsFinder.h"

static const double dragHoverTime = 1;

@implementation PlaylistManager {
  BOOL ignoreSelectionChange;
  NSTimer *dragHoverTimer;
  NSInteger dragHoverRow;

  IBOutlet NSTableView *playlistsTable;
}

- (void)awakeFromNib {
  playlistsTable.target = self;
  playlistsTable.doubleAction = @selector(startPlaylingSelectedPlaylist);

  [playlistsTable registerForDraggedTypes:@[kDragTypeTreeNodes, kDragTypePlaylistsRows, kDragTypePlaylistItemsRows, NSFilenamesPboardType]];

  [self updateSelectedPlaylist];

  [self observe:kFilePlayerEventNotification withAction:@selector(handlePlayerEvent)];

  [ShortcutBinder bindControl:playlistsTable andKey:kMartinKeyDelete toTarget:self andAction:@selector(deleteSelectedPlaylists)];
  [ShortcutBinder bindControl:playlistsTable andKey:kMartinKeyCmdDown toTarget:self andAction:@selector(startPlaylingSelectedPlaylist)];
}

- (id)init {
  if (self = [super init]) {
    [LibManager initLibrary];

    _shuffle = [[DefaultsManager objectForKey:kDefaultsKeyShuffle] boolValue];
    _repeat = [[DefaultsManager objectForKey:kDefaultsKeyRepeat] boolValue];
    _playlists = [PlaylistPersistence loadPlaylists];
  }

  return self;
}

- (QueuePlaylist *)queue {
  return _playlists[0];
}

- (void)reload {
  [playlistsTable reloadData];
}

- (void)setShuffle:(BOOL)shuffle {
  _shuffle = shuffle;
  [DefaultsManager setObject:@(_shuffle) forKey:kDefaultsKeyShuffle];
  for (Playlist *pl in _playlists) [pl shuffle];
}

- (void)setRepeat:(BOOL)repeat {
  _repeat = repeat;
  [DefaultsManager setObject:@(_repeat) forKey:kDefaultsKeyRepeat];
}

- (void)savePlaylists {
  [PlaylistPersistence savePlaylists:_playlists];
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

- (void)addPlaylist:(Playlist *)p {
  [_playlists addObject:p];
  [playlistsTable reloadData];
  [playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_playlists.count-1] byExtendingSelection:NO];
  [self updateSelectedPlaylist];
}

- (void)updateSelectedPlaylist {
  _selectedPlaylist = _playlists[playlistsTable.selectedRow];
  [MartinAppDelegate get].playlistTableManager.playlist = _selectedPlaylist;
}

- (void)handlePlayerEvent {
  [playlistsTable reloadData];
}

- (void)deleteSelectedPlaylists {
  NSMutableIndexSet *is = [[NSMutableIndexSet alloc] initWithIndexSet:[playlistsTable selectedRowIndexes]];
  [is removeIndex:0]; // queue can't be deleted
  [playlistsTable deselectRow:0];

  if (is.count == 0) return;

  [_playlists removeObjectsAtIndexes:is];
  [playlistsTable reloadData];

  // without this first item becomes selected after removing the last one, last item should be selected instead
  if (is.count == 1 && [is lastIndex] == playlistsTable.numberOfRows) {
    [playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:playlistsTable.numberOfRows - 1] byExtendingSelection:NO];
  }

  [self updateSelectedPlaylist];
}

- (void)startPlaylingSelectedPlaylist {
  NSInteger row = playlistsTable.clickedRow;
  if (row == -1) row = playlistsTable.selectedRow;

  [playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
  [[MartinAppDelegate get].player playItemWithIndex:0];
}

#pragma mark - buttons

- (IBAction)deletePlaylistPressed:(id)sender {
  [self deleteSelectedPlaylists];
}

- (IBAction)addPlaylistPressed:(id)sender {
  [_playlists addObject:[Playlist new]];
  [playlistsTable reloadData];
  [playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_playlists.count-1] byExtendingSelection:NO];
}

#pragma mark - drag and drop

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  [pboard declareTypes:@[kDragTypePlaylistsRows] owner:nil];
  [pboard setData:[DragDataConverter dataFromArray:rows]
          forType:kDragTypePlaylistsRows];
  return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  [self resetDragHoverTimer];
  if (dropOperation == NSTableViewDropOn) {
    dragHoverRow = row;
    [self setDragHoverTimer];
  }

  // can't drop anything above the queue
  if (dropOperation == NSTableViewDropAbove && row == 0) return NSDragOperationNone;

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
  [playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:dragHoverRow] byExtendingSelection:NO];
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

  if ([draggingTypes containsObject:NSFilenamesPboardType]) {
    NSArray *items = [info.draggingPasteboard propertyListForType:NSFilenamesPboardType];
    NSArray *playlistItems = [SongsFinder playlistItemsFromFolders:items];

    if (dropOperation == NSTableViewDropAbove) {
      Playlist *p = [[Playlist alloc] initWithPlaylistItems:playlistItems];
      [_playlists insertObject:p atIndex:row];
      [tableView reloadData];
    } else {
      Playlist *p = _playlists[row];
      [p addPlaylistItems:playlistItems];
    }
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self updateSelectedPlaylist];
  } else {
    NSString *draggingType = [draggingTypes lastObject];
    NSArray *items = [DragDataConverter arrayFromData:[info.draggingPasteboard dataForType:draggingType]];

    if ([draggingType isEqualToString:kDragTypePlaylistsRows]) {
      if (dropOperation == NSTableViewDropAbove) {
        [self relocateRows:items toPos:row];
      } else {
        Playlist *destPlaylist = _playlists[row];
        for (NSNumber *n in items) {
          [destPlaylist addItemsFromPlaylist:_playlists[n.intValue]];
        }
        [playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
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

        [_playlists insertObject:p atIndex:row];
        [tableView reloadData];
      } else {
        Playlist *p = _playlists[row];
        if (fromLibrary) [p addTreeNodes:items atPos:p.numberOfItems];
        else [p addPlaylistItems:items];
      }
      [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
      [self updateSelectedPlaylist];
    }
  }

  [[MartinAppDelegate get].window makeFirstResponder:playlistsTable];

  return YES;
}

- (void)relocateRows:(NSArray *)rows toPos:(NSInteger)pos {
  NSMutableIndexSet *rowsToRelocate = [NSMutableIndexSet new];
  NSMutableArray *objectsToRelocate = [NSMutableArray new];
  NSInteger dest = pos;
  for (NSNumber *n in rows) {
    int i = n.intValue;
    if (i > 0) {
      [objectsToRelocate addObject:_playlists[i]];
      [rowsToRelocate addIndex:i];
      if (i < pos) --dest;
    }
  };

  NSIndexSet *destIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(dest, rowsToRelocate.count)];
  [_playlists removeObjectsAtIndexes:rowsToRelocate];
  [_playlists insertObjects:objectsToRelocate atIndexes:destIndexSet];
  [playlistsTable reloadData];
  ignoreSelectionChange = YES;
  [playlistsTable selectRowIndexes:destIndexSet byExtendingSelection:NO];
  ignoreSelectionChange = NO;
}

#pragma mark - table data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return _playlists.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  Playlist *p = (Playlist *)_playlists[row];
  if (row == 0) return [NSString stringWithFormat:@"%@ (%d)", p.name, p.numberOfItems];
  else return p.name;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSString *newName = (NSString *)object;
  ((Playlist*)_playlists[row]).name = [newName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

#pragma mark - table delegate

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if (row == 0) return NO;

  NSEvent *e = [NSApp currentEvent];
  if (e.type == NSKeyDown && e.keyCode == 48) return NO;
  return YES;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)c forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTextFieldCell *cell = (NSTextFieldCell*)c;

  if (_playlists[row] == [MartinAppDelegate get].player.nowPlayingPlaylist) {
    cell.font = [NSFont boldSystemFontOfSize:13];
  } else {
    cell.font = [NSFont systemFontOfSize:13];
  }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
  if (ignoreSelectionChange == NO) {
    [self updateSelectedPlaylist];
  }
}

@end
