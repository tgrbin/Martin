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

@interface TabsManager()
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

- (void)createDummyTabView {
  self.dummyTabView = [NSTabView new];
  _tabBarView.tabView = _dummyTabView;
}

- (void)loadPlaylists {
  NSArray *playlists = [PlaylistPersistence loadPlaylists];

  self.queue = playlists[0];

  for (int i = 1; i < playlists.count; ++i) {
    PlaylistTabBarItem *item = [PlaylistTabBarItem new];
    item.playlist = playlists[i];
    NSTabViewItem *tabItem = [[NSTabViewItem alloc] initWithIdentifier:item];
    [_dummyTabView addTabViewItem:tabItem];
  }

  if (_queue.numberOfItems > 0) {
    [self showQueueTab];
  }
}

#pragma mark - queue

- (void)showQueueTab {
  if (showingQueueTab == YES) {
    return;
  }

  PlaylistTabBarItem *item = [PlaylistTabBarItem new];
  item.playlist = _queue;
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

@end
