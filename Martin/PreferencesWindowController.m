//
//  PreferencesWindowController.m
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import "PreferencesWindowController.h"
#import "LibraryFolder.h"

@implementation PreferencesWindowController

- (id)init {
  return (self = [super initWithWindowNibName:@"PreferencesWindowController"]);
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
  if ([colId isEqualToString:@"includeInRescan"] || [colId isEqualToString:@"treeDisplayName"]) {
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
  panel.directoryURL = [NSURL URLWithString:lf.folderPath];
  
  if ([panel runModal] == NSFileHandlingPanelOKButton) {
    lf.folderPath = [panel.directoryURL absoluteString];
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
  [foldersTableView reloadData];
}

#pragma mark - add new

- (IBAction)addNewPressed:(id)sender {
  NSOpenPanel *panel = [self configurePanel];
  
  if ([panel runModal] == NSFileHandlingPanelOKButton) {
    LibraryFolder *lf = [[LibraryFolder alloc] init];
    lf.folderPath = [panel.directoryURL absoluteString];
    lf.treeDisplayName = [lf.folderPath lastPathComponent];
    lf.includeInRescan = @YES;
    [[LibraryFolder libraryFolders] addObject:lf];
    [foldersTableView reloadData];
  }
}

#pragma mark - window delegate

- (void)windowWillClose:(NSNotification *)notification {
  [LibraryFolder save];
}

@end
