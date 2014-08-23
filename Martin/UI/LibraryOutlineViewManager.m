//
//  DataSource.m
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//

#import "LibraryOutlineViewManager.h"
#import "MartinAppDelegate.h"
#import "LibManager.h"
#import "LibraryTree.h"
#import "LibraryTreeOutlineViewState.h"
#import "LibraryTreeSearch.h"
#import "RescanProxy.h"
#import "RescanState.h"
#import "TreeStateManager.h"
#import "NSObject+Observe.h"
#import "ShortcutBinder.h"
#import "DefaultsManager.h"
#import "Playlist.h"
#import "QueuePlaylist.h"
#import "LibraryOutlineViewDataSource.h"

@interface LibraryOutlineViewManager() <
  NSTextFieldDelegate,
  NSControlTextEditingDelegate,
  NSMenuDelegate
>

@end

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

  [self observe:kStreamsUpdatedNotification withAction:@selector(streamsUpdated)];
  
  [self observe:NSOutlineViewItemDidExpandNotification withAction:@selector(itemDidExpand:)];
  [self observe:NSOutlineViewItemDidCollapseNotification withAction:@selector(itemDidCollapse:)];

  [[MartinAppDelegate get].streamsController addObserver:self
                                              forKeyPath:@"showStreamsInLibraryPane"
                                                 options:0
                                                 context:nil];
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
    [LibraryTreeSearch performSearch:searchQuery];
  }
}

#pragma mark - mouse events

- (void)itemDoubleClicked {
  id item = [outlineView itemAtRow:outlineView.selectedRow];
  if ([self.dataSource isItemLeaf:item]) {
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
  NSArray *paths = [LibraryTree pathsForNodes:treeNodes];
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
  BOOL onlyFolders = YES;
  BOOL streamPresent = NO;
  
  for (id item in items) {
    if ([self.dataSource isItemFromLibrary:item] == NO) {
      streamPresent = YES;
      onlyFolders = NO;
      break;
    } else if ([self.dataSource isItemLeaf:item] == YES) {
      onlyFolders = NO;
      break;
    }
  }

  [[menu itemWithTitle:@"Rescan"] setEnabled:(onlyFolders == YES)];
  [[menu itemWithTitle:@"Show in Finder"] setEnabled:(streamPresent == NO)];
}

#pragma mark - notifications

- (void)searchFinished {
  [outlineView reloadData];
  [self autoExpandSearchResults];
}

- (void)libraryRescanned {
  [outlineView reloadData];
  [LibraryTreeOutlineViewState restoreNodesForStoredInodesAndLevelsToSet:userExpandedItems];
  if (_searchTextField.stringValue.length > 0) {
    [LibraryTreeSearch resetSearchState];
    [LibraryTreeSearch performSearch:_searchTextField.stringValue];
  } else {
    [self closeAllExceptWhatUserOpened];
  }
}

- (void)rescanStateChanged {
  if ([RescanState sharedState].state == kRescanStateReloadingLibrary) {
    [LibraryTreeOutlineViewState storeInodesAndLevelsForNodes:userExpandedItems];
  }

  [[RescanState sharedState] setupProgressIndicator:determinateRescanIndicator
                     indeterminateProgressIndicator:rescanIndicator
                                       andTextField:rescanMessage];
  
  rescanStatusView.hidden = rescanMessage.isHidden;
}

- (void)streamsUpdated {
  [outlineView reloadData];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"showStreamsInLibraryPane"]) {
    [outlineView reloadData];
  }
}

#pragma mark - auto expanding

- (void)autoExpandSearchResults {
  [self closeAllExceptWhatUserOpened];

  if (_searchTextField.stringValue.length > 0) {

    userIsManipulatingTree = NO;
    
    for (int visibleRows = (int) (outlineView.frame.size.height/outlineView.rowHeight) - 5;;) {
      NSInteger n = outlineView.numberOfRows;
      NSMutableArray *itemsToExpand = [NSMutableArray array];
      NSInteger k = -1;

      for (int j = 0; j < 2; ++j) {
        for (int i = 0; i < n; ++i) {
          NSNumber *item = [outlineView itemAtRow:i];
          if ([outlineView isItemExpanded:item] || [self.dataSource isItemLeaf:item]) continue;
          NSInteger nChildren = [self.dataSource numberOfChildrenOfItem:item];
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
}

- (void)closeAllExceptWhatUserOpened {
  userIsManipulatingTree = NO;
  
  [outlineView collapseItem:nil collapseChildren:YES];
  for (id item in userExpandedItems) {
    [self expandWholePathForItem:item];
  }
  
  userIsManipulatingTree = YES;
}

- (void)expandWholePathForItem:(id)item {
  NSMutableArray *arr = [NSMutableArray array];
  
  for (; [item intValue] != 0; item = [self.dataSource parentOfItem:item]) {
    [arr addObject:item];
  }
  
  for(; arr.count > 0; [arr removeLastObject]) {
    [outlineView expandItem:[arr lastObject]];
  }
}

- (void)itemDidExpand:(NSNotification *)notification {
  if (notification.object != outlineView || userIsManipulatingTree == NO) {
    return;
  }

  id item = notification.userInfo[@"NSObject"];

  [userExpandedItems addObject:item];

  for (; [self.dataSource numberOfChildrenOfItem:item] == 1;) {
    item = [self.dataSource childAtIndex:0 ofItem:item];
    [outlineView expandItem:item];
    [userExpandedItems addObject:item];
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
    [LibraryTreeSearch performSearch:val];
  }
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
  if (_searchTextField.stringValue.length == 0) return NO;

  SEL noopSelector = NSSelectorFromString(@"noop:");
  
  if (commandSelector == noopSelector && [ShortcutBinder martinKeyForEvent:[NSApp currentEvent]] == kMartinKeyCmdEnter) {
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
