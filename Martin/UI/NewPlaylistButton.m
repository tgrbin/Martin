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

  [[MartinAppDelegate get].tabsManager addPlaylistWithDraggingInfo:sender
                                                    createPlaylist:YES
                                                         onTheLeft:YES];

  return YES;
}

@end
