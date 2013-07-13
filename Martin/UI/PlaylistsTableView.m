//
//  PlaylistsTableView.m
//  Martin
//
//  Created by Tomislav Grbin on 7/13/13.
//
//

#import "PlaylistsTableView.h"
#import "MartinAppDelegate.h"

@implementation PlaylistsTableView

- (void)draggingExited:(id<NSDraggingInfo>)sender {
  [super draggingExited:sender];
  [[MartinAppDelegate get].playlistManager dragExited];
}

@end
