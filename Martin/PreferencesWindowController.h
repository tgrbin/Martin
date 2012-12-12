//
//  PreferencesWindowController.h
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate> {
// library
  IBOutlet NSTableView *foldersTableView;
  IBOutlet NSButton *rescanLibraryButton;
  IBOutlet NSTextField *rescanStatusTextField;
  IBOutlet NSProgressIndicator *rescanProgressIndicator;
  int totalSongs;

// lastFM
  IBOutlet NSProgressIndicator *lastfmProgressIndicator;
}

@property (nonatomic, assign) BOOL watchFoldersEnabled;

@end
