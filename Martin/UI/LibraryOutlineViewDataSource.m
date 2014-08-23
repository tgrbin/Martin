//
//  LibraryOutlineViewDataSource.m
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import "LibraryOutlineViewDataSource.h"
#import "LibraryTree.h"
#import "MartinAppDelegate.h"
#import "Stream.h"
#import "LibraryTreeSearch.h"
#import "PlaylistItem.h"
#import "DragDataConverter.h"

// Streams item has value of -1, it's children are numbered -2, -3, ...
static const int kOutlineViewStreamsItem = -1;

@interface LibraryOutlineViewDataSource() <NSOutlineViewDataSource>
@end

@implementation LibraryOutlineViewDataSource

- (NSString *)nameForItem:(id)item {
  return [self nameForItem:item withChildrenCount:NO];
}

- (BOOL)isItemLeaf:(id)item {
  return [self numberOfChildrenOfItem:item] == 0;
}

- (id)parentOfItem:(id)item {
  int value = [item intValue];
  
  if (value == kOutlineViewStreamsItem) {
    return @(0);
  } else if (value < kOutlineViewStreamsItem) {
    return @(kOutlineViewStreamsItem);
  } else {
    return @([LibraryTree parentOfNode:value]);
  }
}

- (BOOL)isItemFromLibrary:(id)item {
  return [item intValue] >= 0;
}

- (id)childAtIndex:(NSInteger)index ofItem:(id)item {
  int value = [item intValue];
  
  if (value == kOutlineViewStreamsItem) {
    
    return @(-2 - index);
    
  } else {
    
    if (value == 0 && [self showingStreams] == YES) {
      if (index == [LibraryTree numberOfChildrenForNode:0]) {
        return @(kOutlineViewStreamsItem);
      }
    }
    
    return @([LibraryTree childAtIndex:(int)index forNode:value]);
  }
}

- (NSInteger)numberOfChildrenOfItem:(id)item {
  int value = [item intValue];
  
  if (value == kOutlineViewStreamsItem) {
    
    return [self streams].count;
    
  } else if (value < kOutlineViewStreamsItem) {
    
    return 0;
    
  } else {
    
    NSInteger nChildren = [LibraryTree numberOfChildrenForNode:value];
    
    if (value == 0 && [self showingStreams] == YES && [self streams].count > 0) {
      ++nChildren;
    }
    
    return nChildren;
  }
}

- (void)enumeratePlaylistItemsFromItem:(id)item
                             withBlock:(void (^)(PlaylistItem *))block
{
  NSMutableArray *stack = [NSMutableArray new];
  [stack addObject:item];
  
  while (stack.count > 0) {
    id top = [stack lastObject];
    [stack removeLastObject];
    
    if ([self isItemLeaf:top] == YES) {
      
      PlaylistItem *playlistItem;
      
      if ([self isItemFromLibrary:top]) {
        int song = [LibraryTree songFromNode:[top intValue]];
        playlistItem = [[PlaylistItem alloc] initWithLibrarySong:song];
      } else {
        Stream *stream = [self streams][-[top intValue] - 2];
        playlistItem = [stream createPlaylistItem];
      }
      
      block(playlistItem);
      
    } else {
      for (int i = 0; i < [self numberOfChildrenOfItem:top]; ++i) {
        [stack addObject:[self childAtIndex:i ofItem:top]];
      }
    }
  }
}

#pragma mark - data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  return [self numberOfChildrenOfItem:item];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  return [self childAtIndex:index ofItem:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return [self numberOfChildrenOfItem:item] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  return [self nameForItem:item withChildrenCount:YES];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
  [pboard declareTypes:@[kDragTypeTreeNodes] owner:nil];
  [pboard setData:[DragDataConverter dataFromArray:items]
          forType:kDragTypeTreeNodes];
  return YES;
}

#pragma mark - helper

- (BOOL)showingStreams {
  return [MartinAppDelegate get].streamsController.showStreamsInLibraryPane;
}

- (NSArray *)streams {
  NSMutableArray *streamsMatchingSearch = [NSMutableArray new];

  for (Stream *stream in [MartinAppDelegate get].streamsController.streams) {
    BOOL matches = NO;
    matches = matches || [LibraryTreeSearch currentQueryMatchesString:stream.name];
    matches = matches || [LibraryTreeSearch currentQueryMatchesString:stream.urlString];

    if (matches) {
      [streamsMatchingSearch addObject:stream];
    }
  }
  
  return streamsMatchingSearch;
}

- (NSString *)nameForItem:(id)item withChildrenCount:(BOOL)showChildrenCount {
  int value = [item intValue];
  
  if (value == 0) {
    
    return @"";
    
  } else if (value == kOutlineViewStreamsItem) {
    
    return [self formatItemName:@"Streams"
                      withCount:[self streams].count
                      showCount:showChildrenCount];
    
  } else if (value < kOutlineViewStreamsItem) {
    
    Stream *stream = [self streams][-value - 2];
    return stream.name;
    
  } else {
    NSString *name = [LibraryTree nameForNode:value];
    
    if ([LibraryTree isLeaf:value]) {
      return [name stringByDeletingPathExtension];
    } else {
      return [self formatItemName:name
                        withCount:[LibraryTree numberOfChildrenForNode:value]
                        showCount:showChildrenCount];
    }
  }
}

- (NSString *)formatItemName:(NSString *)name
                   withCount:(NSInteger)count
                   showCount:(BOOL)showCount
{
  if (showCount == NO) {
    return name;
  } else {
    return [NSString stringWithFormat:@"%@ (%ld)", name, count];
  }
}

@end
