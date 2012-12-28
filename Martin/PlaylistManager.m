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

@implementation PlaylistManager

static PlaylistManager *sharedManager = nil;

+ (PlaylistManager *)sharedManager {
  return sharedManager;
}

- (void)awakeFromNib {
  sharedManager = self;
  playlistsTable.target = [Player sharedPlayer];
  playlistsTable.doubleAction = @selector(playlistItemDoubleClicked);
  [playlistsTable registerForDraggedTypes:@[@"MyDragType"]];
  [self updateSelectedPlaylist];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handlePlayerEvent)
                                               name:kFilePlayerEventNotification
                                             object:nil];
}

- (id)init {
  if (self = [super init]) {
    playlists = [NSMutableArray new];
    _shuffle = [[DefaultsManager objectForKey:kDefaultsKeyShuffle] boolValue];
    _repeat = [[DefaultsManager objectForKey:kDefaultsKeyRepeat] boolValue];

    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Playlists" ofType:@"plist"];
    NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:plistPath];

    for (NSString *key in data) {
      NSArray *playlistItemsDictionaries = (NSArray*) data[key];
      NSMutableArray *playlistItems = [NSMutableArray new];
      for (id item in playlistItemsDictionaries) [playlistItems addObject:[[PlaylistItem alloc] initWithDictionary:item]];
      Playlist *playlist = [[Playlist alloc] initWithName:key andPlaylistItems:playlistItems];
      [playlists addObject:playlist];
    }
  }

  return self;
}

- (void)setShuffle:(BOOL)shuffle {
  _shuffle = shuffle;
  [DefaultsManager setObject:@(_shuffle) forKey:kDefaultsKeyShuffle];
  for (Playlist *pl in playlists) [pl shuffle];
}

- (void)setRepeat:(BOOL)repeat {
  _repeat = repeat;
  [DefaultsManager setObject:@(_repeat) forKey:kDefaultsKeyRepeat];
}

- (void)savePlaylists {
  NSMutableArray *keys = [NSMutableArray new];
  NSMutableArray *values = [NSMutableArray new];

  for (Playlist *p in playlists) {
    [keys addObject:p.name];
    NSMutableArray *arr = [NSMutableArray new];
    for (int i = 0; i < p.numberOfItems; ++i) [arr addObject:[p[i] dictionary]];
    [values addObject:arr];
  }

  NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Playlists" ofType:@"plist"];
  NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
  [plistDict writeToFile:plistPath atomically:YES];
}

- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes andName:(NSString *)name {
  [self addPlaylist:[[Playlist alloc] initWithName:name andTreeNodes:nodes]];
}

- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes {
  [self addPlaylist:[[Playlist alloc] initWithTreeNodes:nodes]];
}

- (void)addPlaylist:(Playlist *)p {
  [playlists addObject:p];
  [playlistsTable reloadData];
  [playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:playlists.count-1] byExtendingSelection:NO];
  [self updateSelectedPlaylist];
}

- (void)updateSelectedPlaylist {
  _selectedPlaylist = playlists[playlistsTable.selectedRow];
  [PlaylistTableManager sharedManager].playlist = _selectedPlaylist;
}

- (void)handlePlayerEvent {
  [playlistsTable reloadData];
}

#pragma mark - buttons

- (IBAction)deletePlaylistPressed:(id)sender {
  if (playlists.count > 1) { // nemozes izbrisat sve playliste
    [playlists removeObjectAtIndex:playlistsTable.selectedRow];
    [playlistsTable reloadData];
    [self updateSelectedPlaylist];
  }
}

- (IBAction)addPlaylistPressed:(id)sender {
  [playlists addObject:[Playlist new]];
  [playlistsTable reloadData];
  [playlistsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:playlists.count-1] byExtendingSelection:NO];
}

#pragma mark - drag and drop

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  if (info.draggingSource == [LibraryOutlineViewManager sharedManager].outlineView) {
    return NSDragOperationCopy;
  } else if (info.draggingSource == [PlaylistTableManager sharedManager].playlistTable) {
    return NSDragOperationCopy;
  } else {
    return NSDragOperationNone;
  }
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
  BOOL fromLibrary = info.draggingSource == [LibraryOutlineViewManager sharedManager].outlineView;
  BOOL fromPlaylist = info.draggingSource == [PlaylistTableManager sharedManager].playlistTable;

  if (fromLibrary || fromPlaylist) {
    NSArray *items;

    if (fromLibrary) items = [LibraryOutlineViewManager sharedManager].draggingItems;
    else {
      NSMutableArray *arr = [NSMutableArray new];
      for (NSNumber *row in [PlaylistTableManager sharedManager].dragRows) [arr addObject:_selectedPlaylist[row.intValue]];
      items = arr;
    }

    if (dropOperation == NSTableViewDropOn) {
      Playlist *p = playlists[row];
      if (fromLibrary) [p addTreeNodes:items atPos:p.numberOfItems];
      else [p addPlaylistItems:items];
    } else if (dropOperation == NSTableViewDropAbove) {
      Playlist *p;
      if (fromLibrary) p = [[Playlist alloc] initWithTreeNodes:items];
      else p = [[Playlist alloc] initWithPlaylistItems:items];

      [playlists insertObject:p atIndex:row];
      [tableView reloadData];
    }
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self updateSelectedPlaylist];
    return YES;
  }

  return NO;
}

#pragma mark - table data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return playlists.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  return ((Playlist*)playlists[row]).name;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  ((Playlist*)playlists[row]).name = (NSString *)object;
}

#pragma mark - table delegate

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)c forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTextFieldCell *cell = (NSTextFieldCell*)c;

  if (playlists[row] == [Player sharedPlayer].nowPlayingPlaylist) {
    cell.font = [NSFont boldSystemFontOfSize:13];
  } else {
    cell.font = [NSFont systemFontOfSize:13];
  }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
  [self updateSelectedPlaylist];
}

@end
