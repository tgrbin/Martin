//
//  PlaylistManager.h
//  Martin
//
//  Created by Tomislav Grbin on 10/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Playlist;
@class QueuePlaylist;

@interface PlaylistManager : NSObject <NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>

@property (nonatomic, strong) Playlist *selectedPlaylist;

- (NSArray *)playlistsAtIndexes:(NSArray *)indexes;

- (void)selectNowPlayingPlaylist;

- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes;
- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes andSuggestedName:(NSString *)name;
- (void)addNewPlaylistWithPlaylistItems:(NSArray *)items;
- (void)addNewPlaylistWithPlaylistItems:(NSArray *)items andName:(NSString *)name;

- (void)savePlaylists;

- (void)takeFocus;

- (void)dragExited;

@end
