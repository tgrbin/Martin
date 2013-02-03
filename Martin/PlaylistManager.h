//
//  PlaylistManager.h
//  Martin
//
//  Created by Tomislav Grbin on 10/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Playlist;

@interface PlaylistManager : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) NSMutableArray *playlists;
@property (nonatomic, strong) Playlist *selectedPlaylist;

@property (nonatomic, assign) BOOL shuffle;
@property (nonatomic, assign) BOOL repeat;

- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes;
- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes andName:(NSString *)name;
- (void)addNewPlaylistWithPlaylistItems:(NSArray *)items;

- (void)savePlaylists;

- (void)dragExited;

@end
