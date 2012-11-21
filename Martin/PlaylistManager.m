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

@implementation PlaylistManager

static PlaylistManager *sharedManager = nil;

+ (PlaylistManager *)sharedManager {
  return sharedManager;
}

- (void)awakeFromNib {
  sharedManager = self;
  playlistsTable.target = [Player sharedPlayer];
  playlistsTable.doubleAction = @selector(playlistItemDoubleClicked);
  [self updateSelectedPlaylist];
}

- (id)init {
  if (self = [super init]) {
    playlists = [NSMutableArray new];

    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Playlists" ofType:@"plist"];
    NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    for (NSString *key in data) {
      NSArray *playlistItems = (NSArray*) [data objectForKey:key];
      Playlist *playlist = [[Playlist alloc] initWithName:key array:playlistItems];
      [playlists addObject:playlist];
    }
  }
  
  return self;
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

- (void)updateSelectedPlaylist {
  _selectedPlaylist = [playlists objectAtIndex:playlistsTable.selectedRow];
  [PlaylistTableManager sharedManager].playlist = _selectedPlaylist;
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

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
  [self updateSelectedPlaylist];
}

@end
