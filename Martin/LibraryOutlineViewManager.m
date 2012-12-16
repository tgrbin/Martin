//
//  DataSource.m
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LibraryOutlineViewManager.h"
#import "LibManager.h"
#import "Tree.h"
#import "PlaylistManager.h"
#import "PlaylistTableManager.h"

@implementation LibraryOutlineViewManager

static LibraryOutlineViewManager *sharedManager;

+ (LibraryOutlineViewManager *)sharedManager {
  return sharedManager;
}

- (void)awakeFromNib {
  sharedManager = self;

  [LibManager sharedManager];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reloadTree)
                                               name:kLibManagerRescanedLibraryNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reloadTree)
                                               name:kLibManagerFinishedSearchNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(itemDidExpand:)
                                               name:NSOutlineViewItemDidExpandNotification
                                             object:nil];

  _outlineView.target = self;
  _outlineView.doubleAction = @selector(itemDoubleClicked);

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

#pragma mark - mouse events

- (void)itemDoubleClicked {
  id item = [_outlineView itemAtRow:_outlineView.selectedRow];
  if ([Tree isLeaf:[item intValue]]) {
    [[PlaylistTableManager sharedManager] addTreeNodesToPlaylist:@[item]];
  } else {
    if ([_outlineView isItemExpanded:item]) [_outlineView collapseItem:item];
    else [_outlineView expandItem:item];
  }
}

- (IBAction)contextMenuNewPlaylist:(id)sender {
  [[PlaylistManager sharedManager] addNewPlaylistWithTreeNodes:[self itemsToProcessFromContextMenu]];
}

- (IBAction)contextMenuRescanFolder:(id)sender {
  NSArray *items = [self itemsToProcessFromContextMenu];
  NSString *path = [Tree fullPathForNode:[items[0] intValue]];
  [[LibManager sharedManager] rescanFolder:[path cStringUsingEncoding:NSUTF8StringEncoding] withBlock:^(int p) {
    NSLog(@"%d", p);
  }];
}

- (NSArray *)itemsToProcessFromContextMenu {
  NSIndexSet *selectedRows = _outlineView.selectedRowIndexes;
  NSMutableArray *items = [NSMutableArray new];

  if ([selectedRows containsIndex:_outlineView.clickedRow]) {
    for (NSUInteger row = selectedRows.firstIndex; row != NSNotFound; row = [selectedRows indexGreaterThanIndex:row]) {
      [items addObject:[_outlineView itemAtRow:row]];
    }
  } else {
    [items addObject:[_outlineView itemAtRow:_outlineView.clickedRow]];
  }

  return items;
}

#pragma mark - menu delegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
  NSArray *items = [self itemsToProcessFromContextMenu];
  BOOL onlyFolders = YES;
  for (id item in items) {
    if ([Tree isLeaf:[item intValue]]) {
      onlyFolders = NO;
      break;
    }
  }

  if (onlyFolders) {
    if (menu.numberOfItems == 1) {
      NSMenuItem *item = [NSMenuItem new];
      item.target = self;
      item.action = @selector(contextMenuRescanFolder:);
      [menu addItem:item];
    }

    NSMenuItem *item = [menu itemAtIndex:1];
    item.title = [NSString stringWithFormat:@"Rescan folder%@", items.count > 1? @"s": @""];
  } else {
    if (menu.numberOfItems == 2) [menu removeItemAtIndex:1];
  }
}

#pragma mark - data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  return [Tree numberOfChildrenForNode:[item intValue]];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  return @([Tree childAtIndex:(int)index forNode:[item intValue]]);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return [Tree numberOfChildrenForNode:[item intValue]] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if (item == nil) return @"";

  int n = [Tree numberOfChildrenForNode:[item intValue]];
  NSString *name = [Tree nameForNode:[item intValue]];
  return (n == 0)? [name stringByDeletingPathExtension]: [NSString stringWithFormat:@"%@ (%d)", name, n];
}

#pragma mark - reloading

- (void)reloadTree {
  reloadingTree = YES;

  [_outlineView reloadData];
//  [_outlineView collapseItem:nil collapseChildren:YES];
//
//  int maxVisibleRows = (int) (_outlineView.frame.size.height/_outlineView.rowHeight) - 5;
//
//  for (;;) {
//    int n = (int)_outlineView.numberOfRows;
//
//    NSMutableArray *collapsedItems = [NSMutableArray new];
//    for (int i = 0; i < n; ++i) {
//      id item = [_outlineView itemAtRow:i];
//      if ([_outlineView isItemExpanded:item]) continue;
//      [collapsedItems addObject:item];
//    }
//
//    [collapsedItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//      return [obj1 nChildren] > [obj2 nChildren];
//    }];
//
//    NSMutableArray *itemsToExpand = [NSMutableArray new];
//    for (id item in collapsedItems) {
//      int nc = [item nChildren];
//      if (nc > 0 && n + nc < maxVisibleRows) {
//        n += nc;
//        [itemsToExpand addObject:item];
//      }
//    }
//    if (itemsToExpand.count == 0) break;
//
//    for (id item in itemsToExpand) [_outlineView expandItem:item];
//  }

  reloadingTree = NO;
}

- (void)itemDidExpand:(NSNotification *)notification {
//  if (notification.object != _outlineView) return;
//
//  if (!reloadingTree) {
//    NSMutableArray *itemsToExpand = [NSMutableArray new];
//    for (id item = notification.userInfo[@"NSObject"]; [item nChildren] == 1;) {
//      item = [item getChild:0];
//      [itemsToExpand addObject:item];
//    }
//    for (id item in itemsToExpand) [_outlineView expandItem:item];
//  }
}

#pragma mark - search

- (void)controlTextDidChange:(NSNotification *)obj {
  NSTextView *field = obj.userInfo[@"NSFieldEditor"];
  NSString *query = (field.string == nil)? @"": field.string;
  [[LibManager sharedManager] performSearch:query];
}

@end
