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

  for (Playlist *p in playlists) {
    fprintf(f, " %s\n", [p.name UTF8String]);
    for (int i = 0; i < p.numberOfItems; ++i) {
      [p[i] outputToFileStream:f];
    }
  }

  fprintf(f, " x\n");
  fclose(f);

  unlink([ResourcePath playlistsPath]);
  rename([ResourcePath playlistsHelperPath], [ResourcePath playlistsPath]);
}

+ (NSMutableArray *)loadPlaylists {
  static const int kBuffSize = 1<<16;
  static char buff[kBuffSize];

  NSMutableArray *playlists = [NSMutableArray new];
  NSMutableArray *items = [NSMutableArray new];
  NSString *playlistName = nil;

  FILE *f = fopen([ResourcePath playlistsPath], "r");
  if (f == NULL) {
    [playlists addObject:[[Playlist alloc] initWithName:@"Queue" andPlaylistItems:@[]]];
  } else {
    for (; fgets(buff, kBuffSize, f) != NULL;) {
      buff[strlen(buff)-1] = 0; // remove newline

      if (buff[0] == ' ') {
        if (playlistName != nil) {
          [playlists addObject:[[Playlist alloc] initWithName:playlistName andPlaylistItems:items]];
          [items removeAllObjects];
        }
        playlistName = @(buff+1);
      } else {
        [items addObject:[[PlaylistItem alloc] initWithFileStream:f]];
        fgets(buff, kBuffSize, f); // skip }
      }
    }
  }

  return playlists;
}

@end

