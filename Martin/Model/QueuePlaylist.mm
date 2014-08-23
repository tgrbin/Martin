//
//  QueuePlaylist.m
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import "QueuePlaylist.h"
#import "Playlist.h"
#import "Playlist+private.h"

#import "MartinAppDelegate.h"

@implementation QueuePlaylist

- (id)initWithName:(NSString *)n andPlaylistItems:(NSArray *)arr {
  if (self = [super initWithName:n andPlaylistItems:arr]) {
    isQueue = YES;
  }
  return self;
}

- (id)initWithFileStream:(FILE *)f {
  if (self = [super initWithFileStream:f]) {
    for (int i = 0; i < playlistItems.size(); ++i) itemOrigin.push_back(nil);
    isQueue = YES;
  }
  return self;
}

- (Playlist *)currentItemPlaylist {
  if (playlistItems.size() == 0) return nil;
  return itemOrigin[playlist[0]];
}

- (void)removeFirstItem {
  if ([self isEmpty]) return;
  [self removeSongsAtIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void)clear {
  [self removeSongsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.numberOfItems)]];
}

- (void)dumpItemsOriginWithPlaylists:(NSArray *)playlists toFileStream:(FILE *)f {
  fprintf(f, "%ld\n", itemOrigin.size());
  for (int i = 0; i < itemOrigin.size(); ++i) {
    Playlist *p = itemOrigin[i];
    if (p == nil) {
      fprintf(f, "-1 -1 ");
    } else {
      int index = (int)[playlists indexOfObject:p];
      fprintf(f, "%d %d ", index, [p indexOfPlaylistItem:playlistItems[i]]);
    }
  }
  fprintf(f, "\n");
}

- (void)willRemovePlaylist:(Playlist *)p {
  for (auto it = itemOrigin.begin(); it != itemOrigin.end(); ++it) {
    if (*it == p) *it = nil;
  }
}

- (void)initItemOriginWithIndexArray:(NSArray *)indexArray andPlaylists:(NSArray *)playlists {
  for (int i = 0; i < itemOrigin.size(); ++i) {
    int x = [indexArray[i+i] intValue];
    int y = [indexArray[i+i+1] intValue];

    if (x == -1) itemOrigin[i] = nil;
    else {
      Playlist *p = playlists[x];
      itemOrigin[i] = p;
      playlistItems[i] = p->playlistItems[y];
    }
  }
}

- (int)addPlaylistItems:(NSArray *)arr atPos:(int)pos fromPlaylist:(Playlist *)_playlist {
  int returnVal = [super addPlaylistItems:arr atPos:pos fromPlaylist:_playlist];

  [[MartinAppDelegate get].playlistTableManager queueChanged];
  
  return returnVal;
}

- (int)addTreeNodes:(NSArray *)treeNodes {
  int added = [super addTreeNodes:treeNodes];

  Playlist *playlistToReturnTo;
  if ([MartinAppDelegate get].playerController.nowPlayingPlaylist == self) {
    playlistToReturnTo = [self currentItemPlaylist];
  } else {
    playlistToReturnTo = [MartinAppDelegate get].playerController.nowPlayingPlaylist;
  }
  
  for (int i = (int)itemOrigin.size() - added; i < itemOrigin.size(); ++i) {
    itemOrigin[i] = playlistToReturnTo;
  }
  return added;
}

@end
