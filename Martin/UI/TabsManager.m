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

@interface TabsManager()
@property (unsafe_unretained) IBOutlet MMTabBarView *tabBarView;
@property (nonatomic, strong) NSTabView *dummyTabView;
@end

@implementation TabsManager

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

}

@end
