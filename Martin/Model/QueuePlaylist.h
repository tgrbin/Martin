//
//  QueuePlaylist.h
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import "Playlist.h"

@interface QueuePlaylist : Playlist

- (id)initWithName:(NSString *)n andPlaylistItems:(NSArray *)arr;
- (id)initWithFileStream:(FILE *)f;

- (Playlist *)currentItemPlaylist;

- (void)removeFirstItem;
- (void)clear;

// need playlists array to figure out indexes of pointers it has in items origin
- (void)dumpItemsOriginWithPlaylists:(NSArray *)playlists toFileStream:(FILE *)f;

// set itemsOrigin from this playlist to nil
- (void)willRemovePlaylist:(Playlist *)playlist;

- (void)initItemOriginWithIndexArray:(NSArray *)indexArray andPlaylists:(NSArray *)playlists;

@end
