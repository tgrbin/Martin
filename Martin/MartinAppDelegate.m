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
#import "TreeNode.h"
#import "Playlist.h"
#import "LastFM.h"

@implementation MartinAppDelegate

@synthesize playlistManager, player;
@synthesize songsTableView, outlineView, playlistsTableView;
@synthesize window, dragFromLibrary;

- (void)awakeFromNib {
    songsTableView.target = playlistManager;
    songsTableView.doubleAction = @selector(songDoubleClicked);
    [playlistManager choosePlaylist:[playlistsTableView selectedRow]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [LastFM updateNowPlaying:[LibManager songByID:1] delegate:nil];
    exit(1);
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender {
    [playlistManager savePlaylists];
    return YES;
}

@end
