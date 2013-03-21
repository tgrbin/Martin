//
//  PlaylistPersistence.m
//  Martin
//
//  Created by Tomislav Grbin on 12/29/12.
//
//

#import "PlaylistPersistence.h"
#import "Playlist.h"
#import "PlaylistItem.h"
#import "ResourcePath.h"
#import "Tags.h"

@implementation PlaylistPersistence

+ (void)savePlaylists:(NSArray *)playlists {
  FILE *f = fopen([ResourcePath playlistsHelperPath], "w");

  fprintf(f, "%ld\n", playlists.count);
  for (Playlist *p in playlists) [p outputToFileStream:f];
  fclose(f);

  unlink([ResourcePath playlistsPath]);
  rename([ResourcePath playlistsHelperPath], [ResourcePath playlistsPath]);
}

+ (NSArray *)loadPlaylists {
  NSMutableArray *playlists = [NSMutableArray new];

  FILE *f = fopen([ResourcePath playlistsPath], "r");

  if (f == NULL) {
    [playlists addObject:[[QueuePlaylist alloc] initWithName:@"Queue" andPlaylistItems:@[]]];
  } else {
    int nPlaylists;
    fscanf(f, "%d\n", &nPlaylists);
    for (int i = 0; i < nPlaylists; ++i) {
      Class playlistClass = (i == 0)? [QueuePlaylist class]: [Playlist class];
      [playlists addObject:[[playlistClass alloc] initWithFileStream:f]];
    }
  }

  fclose(f);
  return playlists;
}

@end
