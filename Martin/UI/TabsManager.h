//
//  TabsManager.h
//  Martin
//
//  Created by Tomislav Grbin on 9/21/13.
//
//

#import <Foundation/Foundation.h>

@class Playlist;
@class QueuePlaylist;

@interface TabsManager : NSObject

- (void)allLoaded;

@property (nonatomic, strong) Playlist *selectedPlaylist;

- (void)selectNowPlayingPlaylist;

- (void)savePlaylists;

- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes;
- (void)addNewPlaylistWithTreeNodes:(NSArray *)nodes andSuggestedName:(NSString *)name;
- (void)addNewPlaylistWithPlaylistItems:(NSArray *)items;
- (void)addNewPlaylistWithPlaylistItems:(NSArray *)items andName:(NSString *)name;

- (void)addPlaylistWithDraggingInfo:(id<NSDraggingInfo>)sender createPlaylist:(BOOL)create onTheLeft:(BOOL)left;

- (void)removeTemporaryCmdDragPlaylist;

@property (nonatomic, strong) QueuePlaylist *queue;
- (void)showQueueTab;
- (void)hideQueueTab;
- (void)refreshQueueObjectCount;

- (void)selectNextTab;
- (void)selectPreviousTab;

@end
