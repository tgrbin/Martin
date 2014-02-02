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
#import "PlaylistNameGuesser.h"
#import "DragDataConverter.h"
#import "NSObject+Observe.h"
#import "MMAttachedTabBarButton.h"

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

  [self observe:kFilePlayerEventNotification withAction:@selector(handlePlayerEvent)];
}

- (void)handlePlayerEvent {
  [self updateNowPlayingIndicatorForTabs];
}

- (void)updateNowPlayingIndicatorForTabs {
  [_tabBarView enumerateAttachedButtonsUsingBlock:^(MMAttachedTabBarButton *aButton, NSUInteger idx, BOOL *stop) {
    [aButton updateNowPlayingIndicator];
  }];
}

- (void)allLoaded {
  int index = [[DefaultsManager objectForKey:kDefaultsKeySelectedPlaylistIndex] intValue];
  [_dummyTabView selectTabViewItemAtIndex:index];
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

  int nowPlayingIndex = -1, currentIndex = 0;
  for (NSTabViewItem *tabIitem in _dummyTabView.tabViewItems) {
    PlaylistTabBarItem *item = tabIitem.identifier;
    [playlists addObject:item.playlist];
    if (item.playlist == [MartinAppDelegate get].playerController.nowPlayingPlaylist) {
      nowPlayingIndex = currentIndex;
    }
    ++currentIndex;
  }
  [PlaylistPersistence savePlaylists:playlists];

  int indexToStore = nowPlayingIndex;
  if (indexToStore == -1) {
    indexToStore = (int)[_dummyTabView indexOfTabViewItem:_dummyTabView.selectedTabViewItem];
  }
  [DefaultsManager setObject:@(indexToStore)
                      forKey:kDefaultsKeySelectedPlaylistIndex];
}

- (void)selectNowPlayingPlaylist {
  Playlist *np = [MartinAppDelegate get].playerController.nowPlayingPlaylist;
  if (np) {
    for (NSTabViewItem *tabItem in _dummyTabView.tabViewItems) {
      PlaylistTabBarItem *item = tabItem.identifier;
      if (item.playlist == np) {
        [_dummyTabView selectTabViewItem:tabItem];
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

#pragma mark - next/prev tab

- (void)selectNextTab {
  [_dummyTabView selectNextTabViewItem:self];
}

- (void)selectPreviousTab {
  [_dummyTabView selectPreviousTabViewItem:self];
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

- (void)addPlaylist:(Playlist *)playlist {
  [self addPlaylist:playlist toTheLeft:YES];
}

- (void)addPlaylist:(Playlist *)p toTheLeft:(BOOL)left {
  int index;
  if (left == YES) {
    index = (showingQueueTab == YES)? 1: 0;
  } else {
    index = (int)_dummyTabView.numberOfTabViewItems;
  }
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

  if (playlist == _queue) {
    [MartinAppDelegate get].playerController.nowPlayingPlaylist = [_queue currentItemPlaylist];
    [_queue clear];
    showingQueueTab = NO;
  } else {
    [self.queue willRemovePlaylist:playlist];
    if ([MartinAppDelegate get].playerController.nowPlayingPlaylist == playlist) {
      [MartinAppDelegate get].playerController.nowPlayingPlaylist = nil;
    }
  }
}

- (NSArray *)allowedDraggedTypesForTabView:(NSTabView *)aTabView {
  return @[kDragTypeTreeNodes, kDragTypePlaylistItemsRows, NSFilenamesPboardType];
}

- (BOOL)tabView:(NSTabView *)aTabView acceptedDraggingInfo:(id <NSDraggingInfo>)draggingInfo onTabViewItem:(NSTabViewItem *)tabViewItem {
  [self addPlaylistWithDraggingInfo:draggingInfo
                     createPlaylist:NO
                          onTheLeft:NO];
  return YES;
}

- (void)addPlaylistWithDraggingInfo:(id<NSDraggingInfo>)sender
                     createPlaylist:(BOOL)createPlaylist
                          onTheLeft:(BOOL)left {
  NSPasteboard *pasteboard = sender.draggingPasteboard;
  NSArray *draggingTypes = pasteboard.types;

  if ([draggingTypes containsObject:NSFilenamesPboardType]) {
    NSArray *items = [pasteboard propertyListForType:NSFilenamesPboardType];
    [PlaylistNameGuesser itemsAndNameFromFolders:items withBlock:^(NSArray *items, NSString *name) {
      if (items.count > 0) {
        if (createPlaylist) {
          [self addNewPlaylistWithPlaylistItems:items
                                        andName:name];
        } else {
          [[MartinAppDelegate get].playlistTableManager addPlaylistItems:items];
        }
      }
    }];
  } else {
    NSString *draggingType = [draggingTypes lastObject];
    NSArray *items = [DragDataConverter arrayFromData:[pasteboard dataForType:draggingType]];

    BOOL fromLibrary = [draggingType isEqualToString:kDragTypeTreeNodes];

    if (fromLibrary == NO) {
      Playlist *srcPlaylist = [MartinAppDelegate get].playlistTableManager.dragSourcePlaylist;
      NSMutableArray *arr = [NSMutableArray new];
      for (NSNumber *row in items) [arr addObject:srcPlaylist[row.intValue]];
      items = arr;
    }

    if (createPlaylist) {
      Playlist *p;
      if (fromLibrary) {
        p = [[Playlist alloc] initWithTreeNodes:items];
      } else {
        p = [[Playlist alloc] initWithPlaylistItems:items];
      }
      [self addPlaylist:p toTheLeft:left];
    } else {
      if (fromLibrary) {
        [[MartinAppDelegate get].playlistTableManager addTreeNodes:items];
      } else {
        [[MartinAppDelegate get].playlistTableManager addPlaylistItems:items];
      }
    }
  }
}

- (void)removeTemporaryCmdDragPlaylist {
  NSTabViewItem *tempItem = [_dummyTabView tabViewItemAtIndex:showingQueueTab? 1: 0];
  [self removeTabViewItem:tempItem];
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

- (IBAction)closeTabPressed:(NSMenuItem *)sender {
  [self removeTabViewItem:_dummyTabView.selectedTabViewItem];
}

- (void)removeTabViewItem:(NSTabViewItem *)item {
  [_dummyTabView removeTabViewItem:item];
  [self tabView:_dummyTabView didCloseTabViewItem:item];
}

@end
