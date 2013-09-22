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

static const double kDragHoverTime = 0.4;

@implementation PlaylistManager {
  NSMutableArray *playlists;

  BOOL ignoreSelectionChange;
  NSTimer *dragHoverTimer;

  NSInteger dragHoverRow;

  IBOutlet NSTableView *playlistsTable;
}

- (void)awakeFromNib {
  playlistsTable.target = self;
  playlistsTable.doubleAction = @selector(playSelectedPlaylist:);

  [playlistsTable registerForDraggedTypes:@[kDragTypeTreeNodes, kDragTypePlaylistItemsRows, NSFilenamesPboardType]];

  [self selectRow:[[DefaultsManager objectForKey:kDefaultsKeySelectedPlaylistIndex] intValue]];
  [self updateSelectedPlaylist];

  [self observe:kFilePlayerEventNotification withAction:@selector(handlePlayerEvent)];
}

- (id)init {
  if (self = [super init]) {
    [LibManager initLibrary];
    playlists = [NSMutableArray arrayWithArray:[PlaylistPersistence loadPlaylists]];
  }
  return self;
}

- (NSIndexSet *)offsetSelectedRowsBy:(int)offset {
  NSIndexSet *is = [playlistsTable selectedRowIndexes];
  NSMutableIndexSet *offsetIs = [NSMutableIndexSet new];
  for (NSInteger i = is.firstIndex; i != NSNotFound; i = [is indexGreaterThanIndex:i])
    if (i+offset >= 0) [offsetIs addIndex:i+offset];
  return offsetIs;
}

- (IBAction)addNewEmptyPlaylist:(id)sender {
//  [self addPlaylist:[Playlist new]];
}

- (void)selectRow:(NSInteger)row {
  [playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

- (void)handlePlayerEvent {
  [playlistsTable reloadData];
}

- (void)takeFocus {
  [[MartinAppDelegate get].window makeFirstResponder:playlistsTable];
}

- (IBAction)takeFocus:(id)sender {
  [self takeFocus];
}

- (void)focusPlaylist {
  [[MartinAppDelegate get].playlistTableManager takeFocus];
}

#pragma mark - actions

- (IBAction)renameSelectedPlaylist:(id)sender {
  [playlistsTable editColumn:0
                         row:playlistsTable.clickedRow
                   withEvent:nil
                      select:YES];
}

- (IBAction)deleteSelectedPlaylists:(id)sender {
//  for (NSInteger index = [is firstIndex]; index != NSNotFound; index = [is indexGreaterThanIndex:index]) {
//    [playlists[index] cancelID3Reads];
//    if ([MartinAppDelegate get].player.nowPlayingPlaylist == playlists[index]) {
//      [MartinAppDelegate get].player.nowPlayingPlaylist = nil;
//    }
//    [self.queue willRemovePlaylist:playlists[index]];
//  }

//  if (self.queue.isEmpty == NO && [is containsIndex:0]) {
//    [self.queue clear];
//    [is removeIndex:0];
//  }

//  [playlists removeObjectsAtIndexes:is];
//  [playlistsTable reloadData];
//
//  [self selectRow:MAX(0, MIN(rowToSelect, [self numberOfRows]-1))];
//  [self updateSelectedPlaylist];
}

- (void)updateSelectedPlaylist {}

- (IBAction)playSelectedPlaylist:(id)sender {
  NSInteger row = playlistsTable.clickedRow;
  if (row == -1) row = playlistsTable.selectedRow;
  if (row == -1) return;

  [self selectRow:row];
  [[MartinAppDelegate get].player playSelectedPlaylist];
}

- (IBAction)forgetPlayedItems:(id)sender {
  NSArray *arr = [self chosenItems];
  for (Playlist *p in arr) {
    [p forgetPlayedItems];
  }
}

- (NSArray *)chosenItems {
  NSInteger clickedRow = playlistsTable.clickedRow;
  NSIndexSet *selectedRows = playlistsTable.selectedRowIndexes;
  NSMutableArray *items = [NSMutableArray new];

  if (clickedRow == -1 || [selectedRows containsIndex:clickedRow]) {
    for (NSUInteger row = selectedRows.firstIndex; row != NSNotFound; row = [selectedRows indexGreaterThanIndex:row]) {
      [items addObject:[self playlistAtRow:row]];
    }
  } else {
    [items addObject:[self playlistAtRow:clickedRow]];
  }

  return items;
}

#pragma mark - drag and drop

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  [self resetDragHoverTimer];

  if (dropOperation == NSTableViewDropOn) {
    dragHoverRow = row;
    [self setDragHoverTimer];
  }

// TODO: don't allow tab reorder left of the queue
// can't drop anything above the queue
//  if (self.queue.isEmpty == NO && dropOperation == NSTableViewDropAbove && row == 0) return NSDragOperationNone;

  return NSDragOperationCopy;
}

- (void)setDragHoverTimer {
  dragHoverTimer = [NSTimer scheduledTimerWithTimeInterval:kDragHoverTime
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

    BOOL fromLibrary = [draggingType isEqualToString:kDragTypeTreeNodes];

    if (fromLibrary == NO) {
      Playlist *srcPlaylist = [MartinAppDelegate get].playlistTableManager.dragSourcePlaylist;
      NSMutableArray *arr = [NSMutableArray new];
      for (NSNumber *row in items) [arr addObject:srcPlaylist[row.intValue]];
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

    [[MartinAppDelegate get].window makeFirstResponder:playlistsTable];
  }

  return YES;
}

#pragma mark - table data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [self numberOfRows];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  Playlist *p = [self playlistAtRow:row];
  return p.name;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  Playlist *p = [self playlistAtRow:row];
  NSString *newName = (NSString *)object;
  p.name = [newName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

#pragma mark - table delegate

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
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
  return playlists.count;
}

- (Playlist *)playlistAtRow:(NSInteger)index {
  return playlists[index];
}

#pragma mark - menu delegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
  static const int kRenameItemTag = 1;
  static const int kStateIndicatorTag = 2;

  NSArray *chosenItems = [self chosenItems];

  [menu itemWithTag:kRenameItemTag].enabled = (chosenItems.count == 1);

}

@end
