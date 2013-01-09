//
//  MartinAppDelegate.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MartinAppDelegate.h"

@implementation MartinAppDelegate

+ (MartinAppDelegate *)get {
  return [[NSApplication sharedApplication] delegate];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
  if (flag == NO) [_window makeKeyAndOrderFront:nil];
  return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  [_playlistManager savePlaylists];
  [_libraryOutlineViewManager saveState];
  [_filePlayer storeVolume];
  return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  NSLog(@"%@", filename);
  return NO;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
  NSLog(@"%@", filenames);
  [[NSApplication sharedApplication] replyToOpenOrPrint:NSApplicationDelegateReplyCancel];
}

@end
