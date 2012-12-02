//
//  MartinAppDelegate.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MartinAppDelegate.h"
#import "PlaylistManager.h"
#import "LibManager.h"

@implementation MartinAppDelegate

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
  if (flag == NO) [_window makeKeyAndOrderFront:nil];
  return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  [[PlaylistManager sharedManager] savePlaylists];
  return YES;
}

@end
