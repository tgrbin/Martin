//
//  PlaylistManager.h
//  Martin
//
//  Created by Tomislav Grbin on 10/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MartinAppDelegate, Playlist;

@interface PlaylistManager : NSObject <NSTableViewDataSource,NSTableViewDelegate> {
    Playlist *nowPlayingPlaylist;
    Playlist *selectedPlaylist;
}

@property (nonatomic, retain) NSMutableArray *playlists;
@property (assign) BOOL shuffleOn;

@property (assign) IBOutlet MartinAppDelegate *appDelegate;
@property (nonatomic, retain) IBOutlet NSTableView *table;
@property (nonatomic, retain) IBOutlet NSButton *addPlaylistButton;
@property (nonatomic, retain) IBOutlet NSButton *deleteButton;
@property (nonatomic, retain) IBOutlet NSButton *shuffleButton;

- (IBAction)buttonPressed:(id)sender;
- (void)savePlaylists;
- (void)choosePlaylist:(NSInteger)index;

- (int)currentSongID;
- (int)nextSongID;
- (int)prevSongID;

@end
