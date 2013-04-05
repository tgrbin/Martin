//
//  PlaylistNameGuesser.m
//  Martin
//
//  Created by Tomislav Grbin on 3/10/13.
//
//

#import "PlaylistNameGuesser.h"
#import "Playlist.h"
#import "PlaylistItem.h"
#import "Tree.h"
#import "SongsFinder.h"
#import "MartinAppDelegate.h"

@implementation PlaylistNameGuesser

+ (void)guessNameAndAddItems:(NSArray *)arr toPlaylist:(Playlist *)playlist { // arr contains only treenodes or only playlistitems
  if (arr.count == 0) return;

  BOOL containsPlaylistItems = [arr[0] isKindOfClass:[PlaylistItem class]];

  NSMutableDictionary *counts = [NSMutableDictionary new];
  NSString *onlyAlbum = @"";

  for (id item in arr) {
    if (containsPlaylistItems) {
      NSString *artist = [item tagValueForIndex:kTagIndexArtist];
      if (artist.length > 0) [self addInt:1 toKey:artist inDictionary:counts];

      NSString *album = [item tagValueForIndex:kTagIndexAlbum];
      if (album.length > 0) {
        if (onlyAlbum && onlyAlbum.length == 0) onlyAlbum = album;
        else if ([onlyAlbum isEqualToString:album] == NO) onlyAlbum = nil;
      }

      if (album.length == 0 && artist.length == 0) {
        NSString *folderName = [[((PlaylistItem *)item).filename stringByDeletingLastPathComponent] lastPathComponent];
        [self addInt:1 toKey:folderName inDictionary:counts];
      }
    } else {
      int node = [item intValue];
      int song = [Tree songFromNode:node];
      if (song != -1) node = [Tree parentOfNode:node];

      int oldCount = playlist.numberOfItems;
      [playlist addTreeNodes:@[item]];
      [self addInt:playlist.numberOfItems-oldCount toKey:[Tree nameForNode:node] inDictionary:counts];
    }
  }

  NSArray *ordered = [self orderedCounts:counts];

  NSString *suggestedName;
  if (containsPlaylistItems && onlyAlbum && onlyAlbum.length > 0) {
    suggestedName = [NSString stringWithFormat:@"%@ - %@", ordered[0][0], onlyAlbum];
  } else {
    suggestedName = [self nameFromOrdered:ordered];
  }

  playlist.name = suggestedName;
}

+ (void)itemsAndNameFromFolders:(NSArray *)folders withBlock:(void (^)(NSArray *, NSString *))block {
  ++[MartinAppDelegate get].martinBusy;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSMutableArray *items = [NSMutableArray new];
    NSMutableDictionary *counts = [NSMutableDictionary new];
    for (NSString *folder in folders) {
      int oldCount = (int)items.count;
      [items addObjectsFromArray:[SongsFinder playlistItemsFromFolder:folder]];

      [self addInt:(int)items.count-oldCount
             toKey:[folder lastPathComponent]
      inDictionary:counts];
    }

    NSString *name = [self nameFromOrdered:[self orderedCounts:counts]];

    dispatch_async(dispatch_get_main_queue(), ^{
      block(items, name);
      --[MartinAppDelegate get].martinBusy;
    });
  });
}

+ (void)addInt:(int)x toKey:(NSString *)key inDictionary:(NSMutableDictionary *)dictionary {
  int val = [dictionary[key] intValue];
  dictionary[key] = @(val + x);
}

+ (NSArray *)orderedCounts:(NSDictionary *)counts {
  NSMutableArray *ordered = [NSMutableArray new];
  [counts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) { [ordered addObject:@[key, obj]]; }];
  [ordered sortUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) {return [b[1] compare:a[1]];}];
  return ordered;
}

+ (NSString *)nameFromOrdered:(NSArray *)ordered {
  NSMutableString *name = [NSMutableString stringWithFormat:@"%@", ordered[0][0]];
  if (ordered.count > 1) [name appendFormat:@", %@", ordered[1][0]];
  if (ordered.count > 2) [name appendString:@", ..."];
  return name;
}

@end
