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
@end

@implementation TabsManager {
  BOOL showingQueueTab;
}

- (void)awakeFromNib {
  [self createDummyTabView];
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
  [_dummyTabView addTabViewItem:[self createTabViewItemWithPlaylist:p]];
  [_dummyTabView selectLastTabViewItem:self];
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

@end
