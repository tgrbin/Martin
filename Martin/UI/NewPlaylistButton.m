//
//  NewPlaylistButton.m
//  Martin
//
//  Created by Tomislav Grbin on 9/22/13.
//
//

#import "NewPlaylistButton.h"
#import "MartinAppDelegate.h"
#import "PlaylistNameGuesser.h"
#import "Playlist.h"
#import "DragDataConverter.h"

@implementation NewPlaylistButton

- (void)awakeFromNib {
  [self registerForDraggedTypes:@[kDragTypeTreeNodes, kDragTypePlaylistItemsRows, NSFilenamesPboardType]];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
  [self.cell setHighlighted:YES];
  return NSDragOperationCopy;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
  [self.cell setHighlighted:NO];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
  [self.cell setHighlighted:NO];

  NSPasteboard *pasteboard = sender.draggingPasteboard;
  NSArray *draggingTypes = pasteboard.types;

  if ([draggingTypes containsObject:NSFilenamesPboardType]) {
    NSArray *items = [pasteboard propertyListForType:NSFilenamesPboardType];
    [PlaylistNameGuesser itemsAndNameFromFolders:items withBlock:^(NSArray *items, NSString *name) {
      if (items.count > 0) {
        [[MartinAppDelegate get].tabsManager addNewPlaylistWithPlaylistItems:items
                                                                     andName:name];
      }
    }];
  } else {
    NSString *draggingType = [draggingTypes lastObject];
    NSArray *items = [DragDataConverter arrayFromData:[pasteboard dataForType:draggingType]];

    BOOL fromLibrary = [draggingType isEqualToString:kDragTypeTreeNodes];

    if (fromLibrary == NO) {
      Playlist *srcPlaylist = [MartinAppDelegate get].playlistTableManager.dragSourcePlaylist;
      NSMutableArray *arr = [NSMutableArray new];
      for (NSNumber *row in items) [arr addObject:srcPlaylist[row.intValue]];
      items = arr;
    }

    Playlist *p;
    if (fromLibrary) {
      p = [[Playlist alloc] initWithTreeNodes:items];
    } else {
      p = [[Playlist alloc] initWithPlaylistItems:items];
    }

    [[MartinAppDelegate get].tabsManager addPlaylist:p];
  }

  return YES;
}

@end
