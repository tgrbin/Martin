//
//  PlaylistPersistence.m
//  Martin
//
//  Created by Tomislav Grbin on 12/29/12.
//
//

#import "PlaylistPersistence.h"
#import "Playlist.h"
#import "QueuePlaylist.h"
#import "PlaylistItem.h"
#import "ResourcePath.h"
#import "Tags.h"

@implementation PlaylistPersistence

+ (void)savePlaylists:(NSArray *)playlists {
  FILE *f = fopen([ResourcePath playlistsHelperPath], "w");

  fprintf(f, "%ld\n", playlists.count);
  for (Playlist *p in playlists) {
    [p outputToFileStream:f];
    if (p.isQueue == YES) {
      [(QueuePlaylist *)p dumpItemsOriginWithPlaylists:playlists toFileStream:f];
    }
  }
  fclose(f);

  unlink([ResourcePath playlistsPath]);
  rename([ResourcePath playlistsHelperPath], [ResourcePath playlistsPath]);
}

+ (NSArray *)loadPlaylists {
  NSMutableArray *playlists = [NSMutableArray new];
  NSMutableArray *itemOriginIndexes = [NSMutableArray new];

  FILE *f = fopen([ResourcePath playlistsPath], "r");
  if (f == NULL) {
    [playlists addObject:[[QueuePlaylist alloc] initWithName:@"Queue" andPlaylistItems:@[]]];
    [playlists addObject:[Playlist new]];
  } else {
    int nPlaylists;
    fscanf(f, "%d\n", &nPlaylists);
    for (int i = 0; i < nPlaylists; ++i) {
      Class playlistClass = (i == 0)? [QueuePlaylist class]: [Playlist class];
      [playlists addObject:[[playlistClass alloc] initWithFileStream:f]];

      if (i == 0) {
        int itemOriginSize, x, y;
        fscanf(f, "%d\n", &itemOriginSize);
        for (int i = 0; i < itemOriginSize; ++i) {
          fscanf(f, "%d %d", &x, &y);
          [itemOriginIndexes addObject:@(x)];
          [itemOriginIndexes addObject:@(y)];
          if (i == itemOriginSize-1) fscanf(f, "\n");
        }
      }
    }
    fclose(f);
  }

  [(QueuePlaylist *)playlists[0] initItemOriginWithIndexArray:itemOriginIndexes andPlaylists:playlists];

  return playlists;
}

@end
