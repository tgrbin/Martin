//
//  PreferencesWindowController.h
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate> {
  IBOutlet NSTableView *foldersTableView;
  IBOutlet NSButton *rescanLibraryButton;
  IBOutlet NSTextField *rescanStatusTextField;
  IBOutlet NSProgressIndicator *rescanProgressIndicator;
  
  int totalSongs;
}

@end
