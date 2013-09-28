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

@end
