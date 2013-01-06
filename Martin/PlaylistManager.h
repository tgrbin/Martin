//
//  PlaylistManager.h
//  Martin
//
//  Created by Tomislav Grbin on 10/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Playlist;

@interface PlaylistManager : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
  BOOL ignoreSelectionChange;
  NSTimer *dragHoverTimer;
  NSInteger dragHoverRow;
}

+ (PlaylistManager *)sharedManager;

@property (nonatomic, strong) IBOutlet NSTableView *playlistsTable;
@property (nonatomic, strong) NSMutableArray *playlists;
@property (nonatomic, strong) Playlist *selectedPlaylist;
@property (nonatomic, strong) NSArray *dragRows;

@property (nonatomic, assign) BOOL shuffle;
@property (nonatomic, assign) BOOL repeat;

- (void)savePlaylists;
- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes;
- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes andName:(NSString *)name;

- (void)deleteSelectedPlaylists;
- (void)startPlaylingSelectedPlaylist;

- (void)dragExited;

@end
