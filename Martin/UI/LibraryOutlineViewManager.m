//
//  DataSource.m
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LibraryOutlineViewManager.h"
#import "MartinAppDelegate.h"
#import "LibManager.h"
#import "Tree.h"
#import "RescanProxy.h"
#import "RescanState.h"
#import "TreeStateManager.h"
#import "DragDataConverter.h"
#import "NSObject+Observe.h"
#import "ShortcutBinder.h"
#import "DefaultsManager.h"
#import "Playlist.h"

@implementation LibraryOutlineViewManager {
  BOOL userIsManipulatingTree;
  NSMutableSet *userExpandedItems;

  IBOutlet NSOutlineView *outlineView;

  IBOutlet NSView *rescanStatusView;
  IBOutlet NSProgressIndicator *rescanIndicator;
  IBOutlet NSTextField *rescanMessage;
  IBOutlet NSProgressIndicator *determinateRescanIndicator;
}

- (void)awakeFromNib {
  [self observe:kLibraryRescanFinishedNotification withAction:@selector(libraryRescanned)];
  [self observe:kLibraryRescanTreeReadyNotification withAction:@selector(libraryRescanned)];
  [self observe:kLibrarySearchFinishedNotification withAction:@selector(searchFinished)];
  [self observe:kLibraryRescanStateChangedNotification withAction:@selector(rescanStateChanged)];

  [self observe:NSOutlineViewItemDidExpandNotification withAction:@selector(itemDidExpand:)];
  [self observe:NSOutlineViewItemDidCollapseNotification withAction:@selector(itemDidCollapse:)];

  outlineView.target = self;
  outlineView.doubleAction = @selector(itemDoubleClicked);

  [self initTree];

  [ShortcutBinder bindControl:outlineView andKey:kMartinKeyEnter toTarget:self andAction:@selector(addSelectedItemsToPlaylist:)];
  [ShortcutBinder bindControl:outlineView andKey:kMartinKeyCmdEnter toTarget:self andAction:@selector(createPlaylistWithSelectedItems:)];
  [ShortcutBinder bindControl:outlineView andKey:kMartinKeyQueueItems toTarget:self andAction:@selector(queueSelectedItems:)];

  [ShortcutBinder bindControl:outlineView andKey:kMartinKeySearch toTarget:_searchTextField andAction:@selector(becomeFirstResponder)];
}

- (void)saveState {
  [TreeStateManager saveStateForOutlineView:outlineView];
  [DefaultsManager setObject:_searchTextField.stringValue forKey:kDefaultsKeySearchQuery];
}

#pragma mark - init tree

- (void)initTree {
  [LibManager initLibrary];

  [outlineView reloadData];

  [TreeStateManager restoreStateToOutlineView:outlineView];

  userExpandedItems = [NSMutableSet new];
  for (int i = 0; i < outlineView.numberOfRows; ++i) {
    id item = [outlineView itemAtRow:i];
    if ([outlineView isItemExpanded:item]) [userExpandedItems addObject:item];
  }

  userIsManipulatingTree = YES;
  NSString *searchQuery = [DefaultsManager objectForKey:kDefaultsKeySearchQuery];
  if (searchQuery.length > 0) {
    _searchTextField.stringValue = searchQuery;
    [_searchTextField resignFirstResponder];
    [Tree performSearch:searchQuery];
  }
}

#pragma mark - drag and drop

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
  [pboard declareTypes:@[kDragTypeTreeNodes] owner:nil];
  [pboard setData:[DragDataConverter dataFromArray:items]
          forType:kDragTypeTreeNodes];
  return YES;
}

#pragma mark - mouse events

- (void)itemDoubleClicked {
  id item = [outlineView itemAtRow:outlineView.selectedRow];
  if ([Tree isLeaf:[item intValue]]) {
    [[MartinAppDelegate get].playlistTableManager addTreeNodes:@[item]];
  } else {
    if ([outlineView isItemExpanded:item]) [outlineView collapseItem:item];
    else [outlineView expandItem:item];
  }
}

#pragma mark - context menu actions

- (IBAction)addSelectedItemsToPlaylist:(id)sender {
  [[MartinAppDelegate get].playlistTableManager addTreeNodes:[self chosenItems]];
}

- (IBAction)createPlaylistWithSelectedItems:(id)sender {
  [[MartinAppDelegate get].tabsManager addNewPlaylistWithTreeNodes:[self chosenItems]];
}

- (IBAction)queueSelectedItems:(id)sender {
  NSArray *arr = [self chosenItems];
  if (arr.count > 0) {
    [[MartinAppDelegate get].tabsManager.queue addTreeNodes:arr];
  }
}

- (IBAction)showInFinder:(id)sender {
  NSArray *treeNodes = [self chosenItems];
  NSArray *paths = [Tree pathsForNodes:treeNodes];
  NSMutableArray *urls = [NSMutableArray new];
  for (NSString *path in paths) [urls addObject:[NSURL fileURLWithPath:path]];
  [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
}

- (IBAction)rescan:(id)sender {
  [[RescanProxy sharedProxy] rescanRecursivelyTreeNodes:[self chosenItems]];
}

- (NSArray *)chosenItems {
  NSInteger clickedRow = outlineView.clickedRow;
  NSIndexSet *selectedRows = outlineView.selectedRowIndexes;
  NSMutableArray *items = [NSMutableArray new];

  if (clickedRow == -1 || [selectedRows containsIndex:clickedRow]) {
    for (NSUInteger row = selectedRows.firstIndex; row != NSNotFound; row = [selectedRows indexGreaterThanIndex:row]) {
      [items addObject:[outlineView itemAtRow:row]];
    }
  } else {
    [items addObject:[outlineView itemAtRow:clickedRow]];
  }

  return items;
}

#pragma mark - menu delegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
  NSArray *items = [self chosenItems];
  BOOL onlyItems = YES;
  for (id item in items) {
    if ([Tree isLeaf:[item intValue]] == NO) {
      onlyItems = NO;
      break;
    }
  }

  [[menu itemWithTitle:@"Rescan"] setEnabled:(onlyItems == NO)];
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

#pragma mark - libmanager notifications

- (void)searchFinished {
  [outlineView reloadData];
  [self autoExpandSearchResults];
}

- (void)libraryRescanned {
  [outlineView reloadData];
  [Tree restoreNodesForStoredInodesAndLevelsToSet:userExpandedItems];
  if (_searchTextField.stringValue.length > 0) {
    [Tree resetSearchState];
    [Tree performSearch:_searchTextField.stringValue];
  } else {
    [self closeAllExceptWhatUserOpened];
  }
}

- (void)rescanStateChanged {
  if ([RescanState sharedState].state == kRescanStateReloadingLibrary) {
    [Tree storeInodesAndLevelsForNodes:userExpandedItems];
  }
  [[RescanState sharedState] setupProgressIndicator:determinateRescanIndicator
                     indeterminateProgressIndicator:rescanIndicator
                                       andTextField:rescanMessage];
  rescanStatusView.hidden = rescanMessage.isHidden;
}

#pragma mark - auto expanding

- (void)autoExpandSearchResults {
  [self closeAllExceptWhatUserOpened];

  if (_searchTextField.stringValue.length == 0) return;

  userIsManipulatingTree = NO;
  for (int visibleRows = (int) (outlineView.frame.size.height/outlineView.rowHeight) - 5;;) {
    NSInteger n = outlineView.numberOfRows;
    NSMutableArray *itemsToExpand = [NSMutableArray array];
    int k = -1;

    for (int j = 0; j < 2; ++j) {
      for (int i = 0; i < n; ++i) {
        NSNumber *item = [outlineView itemAtRow:i];
        if ([outlineView isItemExpanded:item] || [Tree isLeaf:item.intValue]) continue;
        int nChildren = [Tree numberOfChildrenForNode:item.intValue];
        if (nChildren == 0) continue;

        if (j == 0) {
          if (k == -1 || k > nChildren) k = nChildren;
        } else {
          if (nChildren == k) [itemsToExpand addObject:item];
        }
      }
    }

    if (itemsToExpand.count == 0 || n + itemsToExpand.count*k > visibleRows) break;
    for (id item in itemsToExpand) [outlineView expandItem:item];
  }
  userIsManipulatingTree = YES;
}

- (void)closeAllExceptWhatUserOpened {
  userIsManipulatingTree = NO;
  [outlineView collapseItem:nil collapseChildren:YES];
  for (id item in userExpandedItems) [self expandWholePathForItem:item];
  userIsManipulatingTree = YES;
}

- (void)expandWholePathForItem:(id)item {
  NSMutableArray *arr = [NSMutableArray array];
  for (int node = [item intValue]; node != -1; node = [Tree parentOfNode:node]) [arr addObject:@(node)];
  for(; arr.count > 0; [arr removeLastObject]) {
    [outlineView expandItem:[arr lastObject]];
  }
}

- (void)itemDidExpand:(NSNotification *)notification {
  if (notification.object != outlineView || userIsManipulatingTree == NO) return;

  id item = notification.userInfo[@"NSObject"];

  [userExpandedItems addObject:item];

  for (int node = [item intValue]; [Tree numberOfChildrenForNode:node] == 1;) {
    node = [Tree childAtIndex:0 forNode:node];
    id child = @(node);
    [outlineView expandItem:child];
    [userExpandedItems addObject:child];
  }
}

- (void)itemDidCollapse:(NSNotification *)notification {
  if (notification.object != outlineView || userIsManipulatingTree == NO) return;

  id item = notification.userInfo[@"NSObject"];
  [userExpandedItems removeObject:item];
}

#pragma mark - search

- (void)controlTextDidChange:(NSNotification *)obj {
  NSString *val = _searchTextField.stringValue;
  if ([val characterAtIndex:val.length-1] == L'œ') { // option+Q pressed
    _searchTextField.stringValue = [val substringToIndex:val.length-1];
    [[MartinAppDelegate get].tabsManager.queue addTreeNodes:@[ @0 ]];
  } else {
    [Tree performSearch:val];
  }
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
  if (_searchTextField.stringValue.length == 0) return NO;

  if (commandSelector == @selector(noop:) && [ShortcutBinder martinKeyForEvent:[NSApp currentEvent]] == kMartinKeyCmdEnter) {
    [[MartinAppDelegate get].tabsManager addNewPlaylistWithTreeNodes:@[ @0 ] andSuggestedName:_searchTextField.stringValue];
    return YES;
  } else if (commandSelector == @selector(insertNewline:)) {
    [[MartinAppDelegate get].playlistTableManager addTreeNodes:@[ @0 ]];
    return YES;
  }

  return NO;
}

- (IBAction)searchPressed:(id)sender {
  [_searchTextField becomeFirstResponder];
}

@end
