//
//  PreferencesWindowController.m
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import "PreferencesWindowController.h"
#import "LibraryFolder.h"
#import "LastFM.h"
#import "FolderWatcher.h"
#import "RescanProxy.h"
#import "RescanState.h"
#import "NSObject+Observe.h"

@implementation PreferencesWindowController {
  // library
  IBOutlet NSTableView *foldersTableView;
  IBOutlet NSButton *rescanLibraryButton;
  IBOutlet NSTextField *rescanStatusTextField;
  IBOutlet NSProgressIndicator *rescanProgressIndicator;
  IBOutlet NSProgressIndicator *rescanDeterminateIndicator;
  int totalSongs;

  // lastFM
  IBOutlet NSProgressIndicator *lastfmProgressIndicator;
}

- (id)init {
  if (self = [super initWithWindowNibName:@"PreferencesWindowController"]) {
    [self observe:kLibraryRescanStateChangedNotification withAction:@selector(rescanStateChanged)];
     _watchFoldersEnabled = [FolderWatcher sharedWatcher].enabled;
  }
  return self;
}

- (void)awakeFromNib {
  rescanLibraryButton.hidden = _watchFoldersEnabled;
}

#pragma mark - watch folders checkbox

- (void)setWatchFoldersEnabled:(BOOL)watchFoldersEnabled {
  _watchFoldersEnabled = watchFoldersEnabled;
  [FolderWatcher sharedWatcher].enabled = watchFoldersEnabled;
  rescanLibraryButton.hidden = watchFoldersEnabled;
  if (_watchFoldersEnabled) [[RescanProxy sharedProxy] rescanAll];
}

#pragma mark - library folders table

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

- (IBAction)changeFolder:(NSTableView *)sender {
  NSString *folderPath = [LibraryFolder libraryFolders][sender.clickedRow];

  NSOpenPanel *panel = [self configurePanel];
  panel.directoryURL = [NSURL fileURLWithPath:folderPath isDirectory:YES];

  if ([panel runModal] == NSFileHandlingPanelOKButton) {
    [LibraryFolder libraryFolders][sender.clickedRow] = [panel.directoryURL path];
    [self folderListChanged];
  }
}

- (NSOpenPanel *)configurePanel {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseDirectories = YES;
  panel.canChooseFiles = NO;
  panel.allowsMultipleSelection = NO;
  return panel;
}

- (IBAction)removeFolder:(id)sender {
  [[LibraryFolder libraryFolders] removeObjectAtIndex:foldersTableView.clickedRow];
  [self folderListChanged];
}

- (void)folderListChanged {
  if (_watchFoldersEnabled) {
    [[FolderWatcher sharedWatcher] folderListChanged];
    [[RescanProxy sharedProxy] rescanAll];
  }

  [LibraryFolder save];
  [foldersTableView reloadData];
}

#pragma mark - buttons

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

#pragma mark - rescan state

- (void)rescanStateChanged {
  [[RescanState sharedState] setupProgressIndicator:rescanDeterminateIndicator
                     indeterminateProgressIndicator:rescanProgressIndicator
                                       andTextField:rescanStatusTextField];
}

#pragma mark - lastfm

- (IBAction)getTokenPressed:(id)sender {
  [self showSpinner];
  [LastFM getAuthURLWithBlock:^(NSString *url) {
    [self hideSpinner];

    if (url == nil) {
      [self showAlertWithMsg:@"Sorry, get token failed."];
    } else {
      [self showAlertWithMsg:@"Allow Martin to scrobble in your browser, and then proceed to getting the session key"];
      [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    }
  }];
}

- (IBAction)getSessionKeyPressed:(id)sender {
  [self showSpinner];
  [LastFM getSessionKey:^(BOOL success) {
    [self hideSpinner];

    if (success == NO) {
      [self showAlertWithMsg:@"Sorry, get session key failed. Make sure you finished previous steps correctly."];
    } else {
      [self showAlertWithMsg:@"That's it! Martin should begin scrobbling now"];
    }
  }];
}

- (IBAction)resetSessionKeyPressed:(id)sender {
  [LastFM resetSessionKey];
  [self showAlertWithMsg:@"Martin is no longer scrobbling."];
}

- (void)showSpinner {
  lastfmProgressIndicator.hidden = NO;
  [lastfmProgressIndicator startAnimation:nil];
}

- (void)hideSpinner {
  lastfmProgressIndicator.hidden = YES;
  [lastfmProgressIndicator stopAnimation:nil];
}

- (void)showAlertWithMsg:(NSString *)msg {
  NSAlert *alert = [NSAlert new];
  [alert setAlertStyle:NSInformationalAlertStyle];
  [alert setMessageText:msg];

  [alert beginSheetModalForWindow:self.window
                    modalDelegate:nil
                    didEndSelector:nil
                       contextInfo:nil];
}

@end
