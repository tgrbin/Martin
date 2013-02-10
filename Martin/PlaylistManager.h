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

@interface PlaylistManager : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) Playlist *selectedPlaylist;

@property (nonatomic, assign) BOOL shuffle;
@property (nonatomic, assign) BOOL repeat;

- (NSArray *)playlistsAtIndexes:(NSArray *)indexes;

- (void)reload;

- (Playlist *)queue;
- (void)queueWillAppear;
- (void)queueWillDisappear;

- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes;
- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes andName:(NSString *)name;
- (void)addNewPlaylistWithPlaylistItems:(NSArray *)items;

- (void)savePlaylists;

- (void)dragExited;

@end
