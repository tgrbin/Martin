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

// Streams item has value of -1, it's children are numbered -2, -3, ...
static const int kOutlineViewStreamsItem = -1;

@interface LibraryOutlineViewDataSource() <NSOutlineViewDataSource>
@end

@implementation LibraryOutlineViewDataSource

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
  int value = [item intValue];
  
  if (value == 0) {
  
    return @"";
  
  } else if (value == kOutlineViewStreamsItem) {
  
    return [NSString stringWithFormat:@"Streams (%ld)", [self streams].count];
  
  } else if (value < kOutlineViewStreamsItem) {
  
    Stream *stream = [self streams][-value - 2];
    return stream.name;
    
  } else {
    NSString *name = [LibraryTree nameForNode:value];

    if ([LibraryTree isLeaf:value]) {
      return [name stringByDeletingPathExtension];
    } else {
      return [NSString stringWithFormat:@"%@ (%d)", name, [LibraryTree numberOfChildrenForNode:value]];
    }
  }
}

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

@end
