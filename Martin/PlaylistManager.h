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

@property (nonatomic, strong) NSMutableArray *playlists;
@property (assign) BOOL shuffleOn;

@property (weak) IBOutlet MartinAppDelegate *appDelegate;
@property (nonatomic, strong) IBOutlet NSTableView *table;
@property (nonatomic, strong) IBOutlet NSButton *addPlaylistButton;
@property (nonatomic, strong) IBOutlet NSButton *deleteButton;
@property (nonatomic, strong) IBOutlet NSButton *shuffleButton;

- (IBAction)buttonPressed:(id)sender;
- (void)savePlaylists;
- (void)choosePlaylist:(NSInteger)index;

- (int)currentSongID;
- (int)nextSongID;
- (int)prevSongID;

@end
