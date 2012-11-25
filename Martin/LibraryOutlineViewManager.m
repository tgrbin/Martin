//
//  DataSource.m
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LibraryOutlineViewManager.h"
#import "LibManager.h"
#import "TreeNode.h"
#import "TreeLeaf.h"

@implementation LibraryOutlineViewManager

static LibraryOutlineViewManager *sharedManager;

+ (LibraryOutlineViewManager *)sharedManager {
  return sharedManager;
}

- (void)awakeFromNib {
  sharedManager = self;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(libraryRescanFinished)
                                               name:kLibManagerRescanedLibraryNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(itemDidExpand:)
                                               name:NSOutlineViewItemDidExpandNotification
                                             object:nil];
  [self reloadTree];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - drag and drop

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
  [pboard declareTypes:@[@"MyDragType"] owner:nil];
  [pboard setData:[NSData data] forType:@"MyDragType"];
  _draggingItems = items;
  return YES;
}

- (void)libraryRescanFinished {
  [self reloadTree];
}

#pragma mark - data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (item == nil) return [[LibManager sharedManager].treeRoot nChildren];
  return [item nChildren];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  if (item == nil) return [[LibManager sharedManager].treeRoot getChild:index];
  return [item getChild:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  if (item == nil) return YES;
  return [item nChildren] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if (item == nil) return @"root";
  if ([item nChildren] == 0) return [item name];
  return [NSString stringWithFormat:@"%@ (%d)", [item name], [item nChildren]];
}

#pragma mark - reloading

- (void)reloadTree {
  reloadingTree = YES;
  
  [_outlineView reloadData];
  [_outlineView collapseItem:nil collapseChildren:YES];
  
  int maxVisibleRows = (int) (_outlineView.frame.size.height/_outlineView.rowHeight) - 5;
  
  for (;;) {
    int n = (int)_outlineView.numberOfRows;
    
    NSMutableArray *collapsedItems = [NSMutableArray new];
    for (int i = 0; i < n; ++i) {
      id item = [_outlineView itemAtRow:i];
      if ([_outlineView isItemExpanded:item]) continue;
      [collapsedItems addObject:item];
    }
    
    [collapsedItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      return [obj1 nChildren] > [obj2 nChildren];
    }];
    
    NSMutableArray *itemsToExpand = [NSMutableArray new];
    for (id item in collapsedItems) {
      int nc = [item nChildren];
      if (nc > 0 && n + nc < maxVisibleRows) {
        n += nc;
        [itemsToExpand addObject:item];
      }
    }
    if (itemsToExpand.count == 0) break;
    
    for (id item in itemsToExpand) [_outlineView expandItem:item];
  }
  
  reloadingTree = NO;
}

- (void)itemDidExpand:(NSNotification *)notification {
  if (!reloadingTree) {
    NSMutableArray *itemsToExpand = [NSMutableArray new];
    for (id item = [notification.userInfo objectForKey:@"NSObject"]; [item nChildren] == 1;) {
      item = [item getChild:0];
      [itemsToExpand addObject:item];
    }
    for (id item in itemsToExpand) [_outlineView expandItem:item];
  }
}

#pragma mark - search

- (IBAction)search:(NSTextField *)sender {
  [[LibManager sharedManager] performSearch:sender.stringValue];
  [self reloadTree];
}

@end
