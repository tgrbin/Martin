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

- (IBAction)deleteSelectedPlaylists:(id)sender {
}

- (void)updateSelectedPlaylist {}

- (IBAction)playSelectedPlaylist:(id)sender {
  NSInteger row = playlistsTable.clickedRow;
  if (row == -1) row = playlistsTable.selectedRow;
  if (row == -1) return;

  [self selectRow:row];
  [[MartinAppDelegate get].player playSelectedPlaylist];
}

#pragma mark - drag and drop

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  [self resetDragHoverTimer];

  if (dropOperation == NSTableViewDropOn) {
    dragHoverRow = row;
    [self setDragHoverTimer];
  }

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

#pragma mark - table delegate

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)c forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
// TODO: make playing playlist display in bold
//  NSTextFieldCell *cell = (NSTextFieldCell*)c;
//  BOOL playingThisPlaylist = [[MartinAppDelegate get].player nowPlayingItemFromPlaylist:[self playlistAtRow:row]];
//  cell.font = playingThisPlaylist? [NSFont boldSystemFontOfSize:13]: [NSFont systemFontOfSize:13];
}

@end
