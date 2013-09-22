//
//  TabsManager.m
//  Martin
//
//  Created by Tomislav Grbin on 9/21/13.
//
//

#import "TabsManager.h"
#import "MMTabBarView.h"

@interface TabsManager()
@property (unsafe_unretained) IBOutlet MMTabBarView *tabBarView;
@property (nonatomic, strong) NSTabView *dummyTabView;
@end

@implementation TabsManager

- (void)awakeFromNib {
  [self createDummyTabView];
}

- (void)createDummyTabView {
  self.dummyTabView = [NSTabView new];
  _tabBarView.tabView = _dummyTabView;
}

@end
