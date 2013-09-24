//
//  TabsManager.m
//  Martin
//
//  Created by Tomislav Grbin on 9/21/13.
//
//

#import "TabsManager.h"
#import "MMTabBarView.h"
#import "PlaylistPersistence.h"
#import "PlaylistTabBarItem.h"
#import "Playlist.h"
#import "DefaultsManager.h"
#import "MartinAppDelegate.h"

@interface TabsManager() <MMTabBarViewDelegate>
@property (unsafe_unretained) IBOutlet MMTabBarView *tabBarView;
@property (nonatomic, strong) NSTabView *dummyTabView;
@property (strong) IBOutlet NSMenu *contextMenu;
@end

@implementation TabsManager {
  BOOL showingQueueTab;
}

- (void)awakeFromNib {
  [self createDummyTabView];
  [self configureMMTabView];
  [self loadPlaylists];
}

- (void)allLoaded {
  [self updateSelectedPlaylist];
}

- (void)createDummyTabView {
  self.dummyTabView = [NSTabView new];
  _tabBarView.tabView = _dummyTabView;
  _dummyTabView.delegate = _tabBarView;
}

- (void)configureMMTabView {
  _tabBarView.onlyShowCloseOnHover = YES;
  [_tabBarView setStyleNamed:@"Card"];
  _tabBarView.buttonMinWidth = 50;
  _tabBarView.buttonMaxWidth = 180;
  _tabBarView.buttonOptimumWidth = 90;
  _tabBarView.sizeButtonsToFit = YES;
}

- (void)loadPlaylists {
  NSArray *playlists = [PlaylistPersistence loadPlaylists];

  self.queue = playlists[0];

  for (int i = 1; i < playlists.count; ++i) {
    [_dummyTabView addTabViewItem:[self createTabViewItemWithPlaylist:playlists[i]]];
  }

  if (_queue.numberOfItems > 0) {
    [self showQueueTab];
  }
}

- (void)savePlaylists {
  NSMutableArray *playlists = [NSMutableArray new];
  if (self.queue.isEmpty == YES) {
    [playlists addObject:_queue];
  }
  for (NSTabViewItem *item in _dummyTabView.tabViewItems) {
    PlaylistTabBarItem *playlistItem = item.identifier;
    [playlists addObject:playlistItem.playlist];
  }
  [PlaylistPersistence savePlaylists:playlists];

  [DefaultsManager setObject:@([_dummyTabView indexOfTabViewItem:_dummyTabView.selectedTabViewItem])
                      forKey:kDefaultsKeySelectedPlaylistIndex];
}

- (void)selectNowPlayingPlaylist {
  Playlist *np = [MartinAppDelegate get].player.nowPlayingPlaylist;
  if (np) {
    for (NSTabViewItem *item in _dummyTabView.tabViewItems) {
      PlaylistTabBarItem *playlistItem = item.identifier;
      if (playlistItem.playlist == np) {
        [_dummyTabView selectTabViewItem:item];
      }
    }
    [self updateSelectedPlaylist];
  }
}

- (void)updateSelectedPlaylist {
  PlaylistTabBarItem *item = [_dummyTabView selectedTabViewItem].identifier;
  _selectedPlaylist = item.playlist;
  [MartinAppDelegate get].playlistTableManager.playlist = _selectedPlaylist;
}

- (NSTabViewItem *)createTabViewItemWithPlaylist:(Playlist *)p {
  PlaylistTabBarItem *item = [[PlaylistTabBarItem alloc] initWithPlaylist:p];
  return [[NSTabViewItem alloc] initWithIdentifier:item];
}

#pragma mark - adding playlists

- (IBAction)newPlaylistPressed:(id)sender {
  [self addPlaylist:[Playlist new]];
}

- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes andSuggestedName:(NSString *)name {
  [self addPlaylist:[[Playlist alloc] initWithSuggestedName:name andTreeNodes:nodes]];
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
  int index = (showingQueueTab == YES)? 1: 0;
  [_dummyTabView insertTabViewItem:[self createTabViewItemWithPlaylist:p]
                           atIndex:index];
  [_dummyTabView selectTabViewItemAtIndex:index];
}

#pragma mark - queue

- (void)showQueueTab {
  if (showingQueueTab == YES) {
    return;
  }

  PlaylistTabBarItem *item = [[PlaylistTabBarItem alloc] initWithPlaylist:_queue];
  item.objectCount = _queue.numberOfItems;
  [_dummyTabView insertTabViewItem:[[NSTabViewItem alloc] initWithIdentifier:item]
                           atIndex:0];
  showingQueueTab = YES;
}

- (void)hideQueueTab {
  if (showingQueueTab == NO) {
    return;
  }

  [_dummyTabView removeTabViewItem:[_dummyTabView tabViewItemAtIndex:0]];

  showingQueueTab = NO;
}

- (void)refreshQueueObjectCount {
  if (showingQueueTab == YES) {
    PlaylistTabBarItem *queueItem = [_dummyTabView tabViewItemAtIndex:0].identifier;
    queueItem.objectCount = _queue.numberOfItems;
  }
}

#pragma mark - tab delegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
  [self updateSelectedPlaylist];
}

- (BOOL)tabView:(NSTabView *)aTabView shouldAllowTabViewItem:(NSTabViewItem *)tabViewItem toLeaveTabBarView:(MMTabBarView *)tabBarView {
  return NO;
}

- (BOOL)tabView:(NSTabView *)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem inTabBarView:(MMTabBarView *)tabBarView {
  PlaylistTabBarItem *item = tabViewItem.identifier;
  return (item.playlist.isQueue == NO);
}

- (void)addNewTabToTabView:(NSTabView *)aTabView {
  [self newPlaylistPressed:self];
}

- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem {
  PlaylistTabBarItem *item = tabViewItem.identifier;
  Playlist *playlist = item.playlist;

  [playlist cancelID3Reads];

  if ([MartinAppDelegate get].player.nowPlayingPlaylist == playlist) {
    [MartinAppDelegate get].player.nowPlayingPlaylist = nil;
  }

  [self.queue willRemovePlaylist:playlist];

  if (playlist == _queue) {
    [_queue clear];
    showingQueueTab = NO;
  }
}

#pragma mark - context menu

- (IBAction)forgetPlayedItems:(NSMenuItem *)sender {
  NSTabViewItem *tabItem = [_dummyTabView tabViewItemAtIndex:sender.tag];
  PlaylistTabBarItem *item = tabItem.identifier;
  [item.playlist forgetPlayedItems];
}

- (NSMenu *)tabView:(NSTabView *)aTabView menuForTabViewItem:(NSTabViewItem *)tabViewItem {
  PlaylistTabBarItem *item = tabViewItem.identifier;
  Playlist *playlist = item.playlist;

  if (playlist.isQueue == YES) {
    return nil;
  }

  [_contextMenu itemAtIndex:0].tag = [_dummyTabView indexOfTabViewItem:tabViewItem];

  [_contextMenu itemAtIndex:1].title = [NSString stringWithFormat:@"%d/%d played",
                                        playlist.numberOfPlayedItems,
                                        playlist.numberOfItems];

  return _contextMenu;
}

@end
