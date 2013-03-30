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
}

#pragma mark - actions

- (IBAction)addNewPressed:(id)sender {
  NSOpenPanel *panel = [self configurePanel];

  if ([panel runModal] == NSFileHandlingPanelOKButton) {
    [[LibraryFolder libraryFolders] addObject:[panel.directoryURL path]];
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

- (IBAction)changeFolder:(id)sender {
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

@end
