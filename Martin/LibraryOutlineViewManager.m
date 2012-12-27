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
#import "RescanProxy.h"
#import "RescanState.h"

@implementation LibraryOutlineViewManager

static LibraryOutlineViewManager *sharedManager;

+ (LibraryOutlineViewManager *)sharedManager {
  return sharedManager;
}

- (void)awakeFromNib {
  sharedManager = self;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(libraryRescanned)
                                               name:kLibraryRescanFinishedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(searchFinished)
                                               name:kLibrarySearchFinishedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(rescanStateChanged)
                                               name:kLibraryRescanStateChangedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(itemDidExpand:)
                                               name:NSOutlineViewItemDidExpandNotification
                                             object:nil];

  _outlineView.target = self;
  _outlineView.doubleAction = @selector(itemDoubleClicked);
  [LibManager initLibrary];
  [_outlineView reloadData];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)rescanStateChanged {
  [[RescanState sharedState] setupProgressIndicator:_rescanIndicator andTextField:_rescanMessage];
  _rescanStatusView.hidden = _rescanMessage.isHidden;
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
  [[RescanProxy sharedProxy] rescanRecursivelyTreeNodes:[self itemsToProcessFromContextMenu]];
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

  int node = [item intValue];
  NSString *name = [Tree nameForNode:node];

  if ([Tree isLeaf:node]) return [name stringByDeletingPathExtension];
  return [NSString stringWithFormat:@"%@ (%d)", name, [Tree numberOfChildrenForNode:node]];
}

#pragma mark - auto expanding

- (void)searchFinished {
  reloadingTree = YES;

  [_outlineView reloadData];
  [_outlineView collapseItem:nil collapseChildren:YES];

  int visibleRows = (int) (_outlineView.frame.size.height/_outlineView.rowHeight) - 5;
  int minRows = MAX(3, visibleRows / 10);

  for (;;) {
    int n = (int)_outlineView.numberOfRows;

    NSMutableArray *itemsToExpand = [NSMutableArray array];
    int m = 0;
    for (int i = 0; i < n; ++i) {
      NSNumber *item = [_outlineView itemAtRow:i];
      if ([_outlineView isItemExpanded:item] || [Tree isLeaf:item.intValue]) continue;
      m += [Tree numberOfChildrenForNode:item.intValue] + 1;
      [itemsToExpand addObject:item];
    }

    if (itemsToExpand.count == 0) break;
    if (n >= minRows && m >= visibleRows) break;

    for (id item in itemsToExpand) [_outlineView expandItem:item];
  }

  reloadingTree = NO;
}

- (void)libraryRescanned {
  [_outlineView reloadData];
  if (_searchTextField.stringValue.length > 0) {
    [Tree resetSearchState];
    [Tree performSearch:_searchTextField.stringValue];
  }
}

- (void)itemDidExpand:(NSNotification *)notification {
  if (notification.object != _outlineView) return;

  if (!reloadingTree) {
    NSMutableArray *itemsToExpand = [NSMutableArray new];
    for (int node = [notification.userInfo[@"NSObject"] intValue]; [Tree numberOfChildrenForNode:node] == 1;) {
      node = [Tree childAtIndex:0 forNode:node];
      [itemsToExpand addObject:@(node)];
    }
    for (id item in itemsToExpand) [_outlineView expandItem:item];
  }
}

#pragma mark - search

- (void)controlTextDidChange:(NSNotification *)obj {
  [Tree performSearch:_searchTextField.stringValue];
}

@end
