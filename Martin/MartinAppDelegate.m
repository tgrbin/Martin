//
//  MartinAppDelegate.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TableSongsDataSource.h"
#import "MartinAppDelegate.h"
#import "PlaylistManager.h"
#import "LibManager.h"
#import "ID3Reader.h"

@implementation MartinAppDelegate

- (void)awakeFromNib {
  _songsTableView.target = _playlistManager;
  _songsTableView.doubleAction = @selector(songDoubleClicked);
  [_playlistManager choosePlaylist:[_playlistsTableView selectedRow]];
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(libraryRescanFinished)
                                               name:kLibManagerRescanedLibraryNotification
                                             object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
  if (flag == NO) [_window makeKeyAndOrderFront:nil];
  return YES;
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender {
  [_playlistManager savePlaylists];
  return YES;
}

- (void)libraryRescanFinished {
  [self.outlineView reloadData];
}

@end
