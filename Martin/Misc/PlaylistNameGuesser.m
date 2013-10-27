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

// arr contains only treenodes or only playlistitems
// playlistitems won't be added to playlist, they should already be in there,
// except when called just with root item
+ (BOOL)guessNameAndAddItems:(NSArray *)arr toPlaylist:(Playlist *)playlist {
  if (arr.count == 0) return NO;

  BOOL containsPlaylistItems = [arr[0] isKindOfClass:[PlaylistItem class]];
  BOOL addingAllNodes = (containsPlaylistItems == NO) && (arr.count == 1 && [arr[0] intValue] == 0);

  if (addingAllNodes) {
    [playlist addTreeNodes:arr];
  }

  NSMutableDictionary *counts = [NSMutableDictionary new];
  NSString *onlyAlbum = @"";

  int N = addingAllNodes? playlist.numberOfItems: (int)arr.count;
  for (int i = 0; i < N; ++i) {
    id item;
    if (addingAllNodes) {
      item = playlist[i];
    } else {
      item = arr[i];
    }

    if (containsPlaylistItems || addingAllNodes) {
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

      [self addInt:[playlist addTreeNodes:@[item]]
             toKey:[Tree nameForNode:node]
      inDictionary:counts];
    }
  }

  NSArray *ordered = [self orderedCounts:counts];

  BOOL suggestionShouldOverrideSearchQuery = NO;

  NSString *suggestedName;
  if ((containsPlaylistItems || addingAllNodes) && onlyAlbum && onlyAlbum.length > 0) {
    suggestedName = [NSString stringWithFormat:@"%@ - %@", ordered[0][0], onlyAlbum];
    suggestionShouldOverrideSearchQuery = YES;
  } else {
    suggestedName = [self nameFromOrdered:ordered];
    suggestionShouldOverrideSearchQuery = (ordered.count == 1);
  }

  playlist.name = suggestedName;

  return suggestionShouldOverrideSearchQuery;
}

+ (void)itemsAndNameFromFolders:(NSArray *)folders withBlock:(void (^)(NSArray *, NSString *))block {
  ++[MartinAppDelegate get].martinBusy;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSMutableArray *items = [NSMutableArray new];
    NSMutableDictionary *counts = [NSMutableDictionary new];
    for (NSString *folder in folders) {
      NSArray *newItems = [SongsFinder playlistItemsFromFolder:folder];
      [items addObjectsFromArray:newItems];

      [self addInt:(int)newItems.count
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
  static const int kMaxCharCount = 19;

  NSMutableString *name = [NSMutableString stringWithFormat:@"%@", ordered[0][0]];
  for (int i = 1; i < ordered.count && name.length < kMaxCharCount; ++i) {
    [name appendFormat:@", %@", ordered[i][0]];
  }

  return name;
}

@end
