//
//  PreferencesWindowController.m
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import "PreferencesWindowController.h"
#import "LibraryFolder.h"
#import "LibManager.h"
#import "LastFM.h"
#import "FolderWatcher.h"

@implementation PreferencesWindowController

- (id)init {
  if (self = [super initWithWindowNibName:@"PreferencesWindowController"]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(libraryRescanFinished)
                                                 name:kLibraryRescanFinishedNotification
                                               object:nil];
    _watchFoldersEnabled = [FolderWatcher sharedWatcher].enabled;
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - watch folders checkbox

- (void)setWatchFoldersEnabled:(BOOL)watchFoldersEnabled {
  _watchFoldersEnabled = watchFoldersEnabled;
  [FolderWatcher sharedWatcher].enabled = watchFoldersEnabled;
}

#pragma mark - library folders table

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [LibraryFolder libraryFolders].count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSString *colId = tableColumn.identifier;
  if (![colId isEqualToString:@"remove"]) {
    LibraryFolder *lf = [[LibraryFolder libraryFolders] objectAtIndex:row];
    return [lf valueForKey:colId];
  }
  return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSString *colId = tableColumn.identifier;
  if ([colId isEqualToString:@"treeDisplayName"]) {
    LibraryFolder *lf = [[LibraryFolder libraryFolders] objectAtIndex:row];
    [lf setValue:object forKey:colId];
  }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if ([tableColumn.identifier isEqualToString:@"folderPath"]) {
    LibraryFolder *lf = [[LibraryFolder libraryFolders] objectAtIndex:row];
    ((NSButtonCell *)cell).title = lf.folderPath;
  }
}

- (IBAction)changeFolder:(NSTableView *)sender {
  LibraryFolder *lf = [[LibraryFolder libraryFolders] objectAtIndex:sender.clickedRow];

  NSOpenPanel *panel = [self configurePanel];
  panel.directoryURL = [NSURL fileURLWithPath:lf.folderPath isDirectory:YES];

  if ([panel runModal] == NSFileHandlingPanelOKButton) {
    lf.folderPath = [panel.directoryURL path];
    [[FolderWatcher sharedWatcher] folderListChanged];
    [sender reloadData];
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
  [[FolderWatcher sharedWatcher] folderListChanged];
  [foldersTableView reloadData];
}

#pragma mark - buttons

- (IBAction)addNewPressed:(id)sender {
  NSOpenPanel *panel = [self configurePanel];

  if ([panel runModal] == NSFileHandlingPanelOKButton) {
    LibraryFolder *lf = [[LibraryFolder alloc] init];
    lf.folderPath = [panel.directoryURL path];
    lf.treeDisplayName = [lf.folderPath lastPathComponent];
    [[LibraryFolder libraryFolders] addObject:lf];
    [foldersTableView reloadData];
  }
}

- (IBAction)rescanPressed:(id)sender {
  [LibraryFolder save];
  rescanLibraryButton.hidden = YES;
  rescanStatusTextField.hidden = NO;
  rescanProgressIndicator.hidden = NO;
  rescanStatusTextField.stringValue = @"Traversing library folders...";
  rescanProgressIndicator.indeterminate = YES;
  [rescanProgressIndicator startAnimation:nil];

  [LibManager rescanLibrary];

//  [[LibManager sharedManager] rescanLibraryWithProgressBlock:^(int p) {
//    if (state == -1) state = p;
//    else if (state != -2) {
//      totalSongs = state;
//      rescanStatusTextField.stringValue = [NSString stringWithFormat:@"Found %d songs, rescanning %d of them..", totalSongs, p];
//      rescanProgressIndicator.indeterminate = NO;
//      rescanProgressIndicator.doubleValue = 0;
//      state = -2;
//    } else {
//      rescanProgressIndicator.doubleValue = p;
//    }
//  }];
}

- (void)libraryRescanFinished {
  rescanStatusTextField.stringValue = [NSString stringWithFormat:@"Done! Total of %d songs in library.", totalSongs];

  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [rescanProgressIndicator stopAnimation:nil];
    rescanProgressIndicator.hidden = YES;
    rescanStatusTextField.hidden = YES;
    rescanLibraryButton.hidden = NO;
  });
}

#pragma mark - window delegate

- (void)windowWillClose:(NSNotification *)notification {
  [LibraryFolder save];
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
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setAlertStyle:NSInformationalAlertStyle];
  [alert setMessageText:msg];

  [alert beginSheetModalForWindow:self.window
                    modalDelegate:nil
                    didEndSelector:nil
                       contextInfo:nil];
}

@end
