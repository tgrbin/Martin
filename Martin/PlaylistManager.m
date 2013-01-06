//
//  PlaylistManager.m
//  Martin
//
//  Created by Tomislav Grbin on 10/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaylistManager.h"
#import "Playlist.h"
#import "PlaylistTableManager.h"
#import "PlaylistItem.h"
#import "Player.h"
#import "LibraryOutlineViewManager.h"
#import "FilePlayer.h"
#import "DefaultsManager.h"
#import "PlaylistPersistence.h"
#import "LibManager.h"
#import "DragDataConverter.h"
#import "NSObject+Observe.h"

@implementation PlaylistManager

static const double dragHoverTime = 1;

static PlaylistManager *sharedManager = nil;

+ (PlaylistManager *)sharedManager {
  return sharedManager;
}

- (void)awakeFromNib {
  sharedManager = self;

  _playlistsTable.target = self;
  _playlistsTable.doubleAction = @selector(startPlaylingSelectedPlaylist);

  [_playlistsTable registerForDraggedTypes:@[kDragTypeTreeNodes, kDragTypePlaylistsRows, kDragTypePlaylistItemsRows]];

  [self updateSelectedPlaylist];

  [self observe:kFilePlayerEventNotification withAction:@selector(handlePlayerEvent)];
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

- (void)addPlaylist:(Playlist *)p {
  [_playlists addObject:p];
  [_playlistsTable reloadData];
  [_playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_playlists.count-1] byExtendingSelection:NO];
  [self updateSelectedPlaylist];
}

- (void)updateSelectedPlaylist {
  _selectedPlaylist = _playlists[_playlistsTable.selectedRow];
  [PlaylistTableManager sharedManager].playlist = _selectedPlaylist;
}

- (void)handlePlayerEvent {
  [_playlistsTable reloadData];
}

- (void)deleteSelectedPlaylists {
  NSIndexSet *is = [_playlistsTable selectedRowIndexes];
  if (_playlists.count - is.count < 1) return; // at least one playlist must remain

  [_playlists removeObjectsAtIndexes:is];
  [_playlistsTable reloadData];
  [_playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_playlistsTable.selectedRow] byExtendingSelection:NO];
  [self updateSelectedPlaylist];
}

- (void)startPlaylingSelectedPlaylist {
  NSInteger row = _playlistsTable.clickedRow;
  if (row == -1) row = _playlistsTable.selectedRow;

  [_playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
  [[Player sharedPlayer] playItemWithIndex:0];
}

#pragma mark - buttons

- (IBAction)deletePlaylistPressed:(id)sender {
  [self deleteSelectedPlaylists];
}

- (IBAction)addPlaylistPressed:(id)sender {
  [_playlists addObject:[Playlist new]];
  [_playlistsTable reloadData];
  [_playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:_playlists.count-1] byExtendingSelection:NO];
}

#pragma mark - drag and drop

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  [pboard declareTypes:@[kDragTypePlaylistsRows] owner:nil];
  [pboard setData:[DragDataConverter dataFromArray:rows]
          forType:kDragTypePlaylistsRows];
  return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  if (info.draggingSource == [LibraryOutlineViewManager sharedManager].outlineView
   || info.draggingSource == [PlaylistTableManager sharedManager].playlistTable
   || info.draggingSource == _playlistsTable)
  {
    [self resetDragHoverTimer];
    if (dropOperation == NSTableViewDropOn) {
      dragHoverRow = row;
      [self setDragHoverTimer];
    }

    return NSDragOperationCopy;
  }

  return NSDragOperationNone;
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
  [_playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:dragHoverRow] byExtendingSelection:NO];
}

- (void)dragExited {
  [self resetDragHoverTimer];
}

- (void)resetDragHoverTimer {
  [dragHoverTimer invalidate];
  dragHoverTimer = nil;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
  NSString *draggingType = [info.draggingPasteboard.types lastObject];
  NSArray *items = [DragDataConverter arrayFromData:[info.draggingPasteboard dataForType:draggingType]];

  if ([draggingType isEqualToString:kDragTypePlaylistsRows]) {
    if (dropOperation == NSTableViewDropAbove) {
      [self relocateRows:items toPos:row];
    } else {
      Playlist *destPlaylist = _playlists[row];
      for (NSNumber *n in items) {
        [destPlaylist addItemsFromPlaylist:_playlists[n.intValue]];
      }
      [_playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
  } else {
    BOOL fromLibrary = [draggingType isEqualToString:kDragTypeTreeNodes];

    if (fromLibrary == NO) {
      NSMutableArray *arr = [NSMutableArray new];
      for (NSNumber *row in items) [arr addObject:_selectedPlaylist[row.intValue]];
      items = arr;
    }

    if (dropOperation == NSTableViewDropOn) {
      Playlist *p = _playlists[row];
      if (fromLibrary) [p addTreeNodes:items atPos:p.numberOfItems];
      else [p addPlaylistItems:items];
    } else if (dropOperation == NSTableViewDropAbove) {
      Playlist *p;
      if (fromLibrary) p = [[Playlist alloc] initWithTreeNodes:items];
      else p = [[Playlist alloc] initWithPlaylistItems:items];

      [_playlists insertObject:p atIndex:row];
      [tableView reloadData];
    }
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self updateSelectedPlaylist];
  }

  return YES;
}

- (void)relocateRows:(NSArray *)rows toPos:(NSInteger)pos {
  NSMutableIndexSet *rowsToRelocate = [NSMutableIndexSet new];
  NSMutableArray *objectsToRelocate = [NSMutableArray new];
  NSInteger dest = pos;
  for (NSNumber *n in rows) {
    int i = n.intValue;
    [objectsToRelocate addObject:_playlists[i]];
    [rowsToRelocate addIndex:i];
    if (i < pos) --dest;
  };

  NSIndexSet *destIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(dest, rows.count)];
  [_playlists removeObjectsAtIndexes:rowsToRelocate];
  [_playlists insertObjects:objectsToRelocate atIndexes:destIndexSet];
  [_playlistsTable reloadData];
  ignoreSelectionChange = YES;
  [_playlistsTable selectRowIndexes:destIndexSet byExtendingSelection:NO];
  ignoreSelectionChange = NO;
}

#pragma mark - table data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return _playlists.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  return ((Playlist*)_playlists[row]).name;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSString *newName = (NSString *)object;
  ((Playlist*)_playlists[row]).name = [newName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

#pragma mark - table delegate

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)c forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTextFieldCell *cell = (NSTextFieldCell*)c;

  if (_playlists[row] == [Player sharedPlayer].nowPlayingPlaylist) {
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
