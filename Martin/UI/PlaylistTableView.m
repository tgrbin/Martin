//
//  PlaylistsTableView.m
//  Martin
//
//  Created by Tomislav Grbin on 7/13/13.
//
//

#import "PlaylistTableView.h"
#import "MartinAppDelegate.h"

@implementation PlaylistTableView {
  BOOL cmdDragInProgress;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
  if ([self cmdPressed:sender]) {
    cmdDragInProgress = YES;
    
    [[MartinAppDelegate get].tabsManager addPlaylistWithDraggingInfo:sender
                                                      createPlaylist:YES
                                                           onTheLeft:YES];
    return NSDragOperationNone;
  }
  
  return [super draggingEntered:sender];
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
  if (cmdDragInProgress == YES) {
    return NSDragOperationNone;
  }
  
  return [super draggingUpdated:sender];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
  [super draggingExited:sender];
  
  // this method gets called even if cmd+drag ends within bounds,
  // which should be accepted and new playlist shouldn't be removed
  CGPoint location = [sender draggingLocation];
  BOOL falseExit = NSPointInRect(location, [self convertRect:self.bounds toView:nil]);
  
  if (falseExit == NO && cmdDragInProgress == YES) {
    [[MartinAppDelegate get].tabsManager removeTemporaryCmdDragPlaylist];
  }

  cmdDragInProgress = NO;
}

- (BOOL)cmdPressed:(id<NSDraggingInfo>)sender {
  NSDragOperation mask = [sender draggingSourceOperationMask];
  return (mask != NSDragOperationEvery && (mask&NSDragOperationGeneric) > 0);
}

@end
