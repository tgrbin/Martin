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
#import "TreeStateManager.h"

@implementation LibraryOutlineViewManager {
  BOOL userIsManipulatingTree;
  NSMutableSet *userExpandedItems;
}

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
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(itemDidCollapse:)
                                               name:NSOutlineViewItemDidCollapseNotification
                                             object:nil];

  _outlineView.target = self;
  _outlineView.doubleAction = @selector(itemDoubleClicked);

  [self initTree];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)rescanStateChanged {
  [[RescanState sharedState] setupProgressIndicator:_determinateRescanIndicator
                     indeterminateProgressIndicator:_rescanIndicator
                                       andTextField:_rescanMessage];
  _rescanStatusView.hidden = _rescanMessage.isHidden;
}

#pragma mark - init tree

- (void)initTree {
  [LibManager initLibrary];
  [_outlineView reloadData];

  [TreeStateManager restoreState];

  userExpandedItems = [NSMutableSet new];
  for (int i = 0; i < _outlineView.numberOfRows; ++i) {
    id item = [_outlineView itemAtRow:i];
    if ([_outlineView isItemExpanded:item]) [userExpandedItems addObject:item];
  }
  userIsManipulatingTree = YES;
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

- (IBAction)contextMenuAddToPlaylist:(id)sender {
  [[PlaylistTableManager sharedManager] addTreeNodesToPlaylist:[self itemsToProcessFromContextMenu]];
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
    if (menu.numberOfItems == 2) {
      NSMenuItem *item = [NSMenuItem new];
      item.target = self;
      item.action = @selector(contextMenuRescanFolder:);
      [menu addItem:item];
    }

    NSMenuItem *item = [menu itemAtIndex:2];
    item.title = [NSString stringWithFormat:@"Rescan folder%@", items.count > 1? @"s": @""];
  } else {
    if (menu.numberOfItems == 3) [menu removeItemAtIndex:2];
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
  [_outlineView reloadData];
  [self autoExpandSearchResults];
}

- (void)libraryRescanned {
  [_outlineView reloadData];
  if (_searchTextField.stringValue.length > 0) {
    [Tree resetSearchState];
    [Tree performSearch:_searchTextField.stringValue];
  }
}

- (void)autoExpandSearchResults {
  userIsManipulatingTree = NO;

  [_outlineView collapseItem:nil collapseChildren:YES];
  for (id item in userExpandedItems) [self expandWholePathForItem:item];

  for (int visibleRows = (int) (_outlineView.frame.size.height/_outlineView.rowHeight) - 5;;) {
    NSInteger n = _outlineView.numberOfRows;
    NSMutableArray *itemsToExpand = [NSMutableArray array];
    int k = -1;

    for (int j = 0; j < 2; ++j) {
      for (int i = 0; i < n; ++i) {
        NSNumber *item = [_outlineView itemAtRow:i];
        if ([_outlineView isItemExpanded:item] || [Tree isLeaf:item.intValue]) continue;
        int nChildren = [Tree numberOfChildrenForNode:item.intValue];

        if (j == 0) {
          if (k == -1 || k > nChildren) k = nChildren;
        } else {
          if (nChildren == k) [itemsToExpand addObject:item];
        }
      }
    }

    if (itemsToExpand.count == 0 || n + itemsToExpand.count*k > visibleRows) break;
    for (id item in itemsToExpand) [_outlineView expandItem:item];
  }

  userIsManipulatingTree = YES;
}

- (void)expandWholePathForItem:(id)item {
  NSMutableArray *arr = [NSMutableArray array];
  for (int node = [item intValue]; node != -1; node = [Tree parentOfNode:node]) [arr addObject:@(node)];
  for(; arr.count > 0; [arr removeLastObject]) {
    [_outlineView expandItem:[arr lastObject]];
  }
}

- (void)itemDidExpand:(NSNotification *)notification {
  if (notification.object != _outlineView || userIsManipulatingTree == NO) return;

  id item = notification.userInfo[@"NSObject"];

  [userExpandedItems addObject:item];

  for (int node = [item intValue]; [Tree numberOfChildrenForNode:node] == 1;) {
    node = [Tree childAtIndex:0 forNode:node];
    id child = @(node);
    [_outlineView expandItem:child];
    [userExpandedItems addObject:child];
  }
}

- (void)itemDidCollapse:(NSNotification *)notification {
  if (notification.object != _outlineView || userIsManipulatingTree == NO) return;

  id item = notification.userInfo[@"NSObject"];
  [userExpandedItems removeObject:item];
}

#pragma mark - search

- (void)controlTextDidChange:(NSNotification *)obj {
  [Tree performSearch:_searchTextField.stringValue];
}

- (BOOL)isCommandEnterEvent:(NSEvent *)e {
  NSUInteger flags = (e.modifierFlags & NSDeviceIndependentModifierFlagsMask);
  BOOL isCommand = (flags & NSCommandKeyMask) == NSCommandKeyMask;
  BOOL isEnter = (e.type == NSEnterCharacter || e.type == NSNewlineCharacter || e.type == NSCarriageReturnCharacter);
  return (isCommand && isEnter);
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
  if (_searchTextField.stringValue.length == 0) return NO;

  if (commandSelector == @selector(noop:) && [self isCommandEnterEvent:[NSApp currentEvent]]) {
    [[PlaylistManager sharedManager] addNewPlaylistWithTreeNodes:@[ @0 ] andName:_searchTextField.stringValue];
    return YES;
  } else if (commandSelector == @selector(insertNewline:)) {
    [[PlaylistTableManager sharedManager] addTreeNodesToPlaylist:@[ @0 ]];
    return YES;
  }

  return NO;
}

@end
