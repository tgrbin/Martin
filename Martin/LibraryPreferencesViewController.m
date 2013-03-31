//
//  LibraryPreferencesViewController.m
//  Martin
//
//  Created by Tomislav Grbin on 3/30/13.
//
//

#import "LibraryPreferencesViewController.h"
#import "NSObject+Observe.h"
#import "FolderWatcher.h"
#import "LibraryFolder.h"
#import "RescanProxy.h"
#import "RescanState.h"
#import "DragDataConverter.h"

@interface LibraryPreferencesViewController ()
@property (nonatomic, assign) BOOL watchFoldersEnabled;

@property (strong) IBOutlet NSButton *rescanLibraryButton;
@property (strong) IBOutlet NSTableView *foldersTableView;

@property (strong) IBOutlet NSProgressIndicator *rescanDeterminateIndicator;
@property (strong) IBOutlet NSProgressIndicator *rescanProgressIndicator;
@property (strong) IBOutlet NSTextField *rescanStatusTextField;
@end

@implementation LibraryPreferencesViewController

- (id)init {
  if (self = [super init]) {
    self.title = @"Library";
    [self observe:kLibraryRescanStateChangedNotification withAction:@selector(rescanStateChanged)];
     _watchFoldersEnabled = [FolderWatcher sharedWatcher].enabled;
  }
  return self;
}

- (void)awakeFromNib {
  _rescanLibraryButton.hidden = _watchFoldersEnabled;
  _foldersTableView.target = self;
  _foldersTableView.doubleAction = @selector(changeFolder);

  [_foldersTableView registerForDraggedTypes:@[kDragTypeLibraryFolderRow, NSFilenamesPboardType]];
}

#pragma mark - actions

- (IBAction)addNewPressed:(id)sender {
  NSOpenPanel *panel = [self configurePanel];
  panel.allowsMultipleSelection = YES;

  if ([panel runModal] == NSFileHandlingPanelOKButton) {
    for (NSURL *url in panel.URLs) {
      [[LibraryFolder libraryFolders] addObject:[url path]];
    }
    [self folderListChanged];
  }
}

- (IBAction)rescanPressed:(id)sender {
  [[RescanProxy sharedProxy] rescanAll];
}

- (void)setWatchFoldersEnabled:(BOOL)watchFoldersEnabled {
  _watchFoldersEnabled = watchFoldersEnabled;
  [FolderWatcher sharedWatcher].enabled = watchFoldersEnabled;
  _rescanLibraryButton.hidden = watchFoldersEnabled;
  if (_watchFoldersEnabled) [[RescanProxy sharedProxy] rescanAll];
}

- (void)changeFolder {
  NSInteger row = _foldersTableView.clickedRow;
  if (row == -1) return;

  NSString *folderPath = [LibraryFolder libraryFolders][row];

  NSOpenPanel *panel = [self configurePanel];
  panel.directoryURL = [NSURL fileURLWithPath:folderPath isDirectory:YES];

  if ([panel runModal] == NSFileHandlingPanelOKButton) {
    [LibraryFolder libraryFolders][row] = [panel.directoryURL path];
    [self folderListChanged];
  }
}

- (IBAction)removeFolder:(id)sender {
  [[LibraryFolder libraryFolders] removeObjectAtIndex:_foldersTableView.clickedRow];
  [self folderListChanged];
}

#pragma mark - util

- (void)rescanStateChanged {
  [[RescanState sharedState] setupProgressIndicator:_rescanDeterminateIndicator
                     indeterminateProgressIndicator:_rescanProgressIndicator
                                       andTextField:_rescanStatusTextField];
}

- (NSOpenPanel *)configurePanel {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseDirectories = YES;
  panel.canChooseFiles = NO;
  panel.allowsMultipleSelection = NO;
  return panel;
}

- (void)folderListChanged {
  if (_watchFoldersEnabled) {
    [[FolderWatcher sharedWatcher] folderListChanged];
    [[RescanProxy sharedProxy] rescanAll];
  }

  [LibraryFolder save];
  [_foldersTableView reloadData];
}

#pragma mark - table

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [LibraryFolder libraryFolders].count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if ([tableColumn.identifier isEqualToString:@"remove"]) return nil;

  return [LibraryFolder libraryFolders][row];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if ([tableColumn.identifier isEqualToString:@"folderPath"]) {
    ((NSButtonCell *)cell).title = [LibraryFolder libraryFolders][row];
  }
}

#pragma mark - reordering

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  [pboard declareTypes:@[kDragTypeLibraryFolderRow] owner:nil];
  [pboard setData:[DragDataConverter dataFromArray:rows]
          forType:kDragTypeLibraryFolderRow];
  return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
  return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
  NSString *draggingType = [info.draggingPasteboard.types lastObject];

  if ([draggingType isEqualToString:kDragTypeLibraryFolderRow]) { // rows reorder
    NSArray *items = [DragDataConverter arrayFromData:[info.draggingPasteboard dataForType:kDragTypeLibraryFolderRow]];
    int srcRow = [items[0] intValue];

    NSMutableArray *arr = [LibraryFolder libraryFolders];
    id tmp = arr[srcRow];
    [arr removeObjectAtIndex:srcRow];
    if (srcRow < row) --row;
    [arr insertObject:tmp atIndex:row];

    [_foldersTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self folderListChanged];
  } else {
    NSArray *items = [info.draggingPasteboard propertyListForType:NSFilenamesPboardType];

    BOOL addedSomething = NO;
    for (NSString *item in items) {
      BOOL isDir;
      if ([[NSFileManager defaultManager] fileExistsAtPath:item isDirectory:&isDir] && isDir == YES) {
        [[LibraryFolder libraryFolders] addObject:item];
        addedSomething = YES;
      }
    }

    if (addedSomething) [self folderListChanged];
  }

  return YES;
}

@end
