//
//  PlaylistManager.h
//  Martin
//
//  Created by Tomislav Grbin on 10/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MartinAppDelegate;
@class Playlist;
@class PlaylistItem;

@interface PlaylistManager : NSObject <NSTableViewDataSource,NSTableViewDelegate> {
  Playlist *nowPlayingPlaylist;
  Playlist *selectedPlaylist;
  
  NSMutableArray *playlists;
  BOOL shuffleOn;
  
  IBOutlet MartinAppDelegate *appDelegate;
  IBOutlet NSTableView *playlistsTable;
}

- (void)choosePlaylist:(NSInteger)index;
- (void)savePlaylists;

- (PlaylistItem *)currentItem;
- (PlaylistItem *)nextItem;
- (PlaylistItem *)prevItem;

- (void)songDoubleClicked;

@end
