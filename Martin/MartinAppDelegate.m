//
//  MartinAppDelegate.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MartinAppDelegate.h"
#import "GlobalShortcuts.h"

@implementation MartinAppDelegate

+ (void)initialize {
  [GlobalShortcuts initShortcuts];
}

+ (MartinAppDelegate *)get {
  return [[NSApplication sharedApplication] delegate];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
  if (flag == NO) [_window makeKeyAndOrderFront:nil];
  return YES;
}

- (void)applicationWillBecomeActive:(NSNotification *)notification {
  if (_window.isVisible == NO) {
    [_window makeKeyAndOrderFront:nil];
  }
}

- (void)toggleMartinVisible {
  BOOL inForeground = [NSApp isActive];
  BOOL isVisible = _window.isVisible;
  if (inForeground) {
    if (isVisible == YES) {
      [_window performClose:nil];
      if ([_preferencesWindowController isWindowLoaded] && _preferencesWindowController.window.isVisible == YES) {
        [_preferencesWindowController.window performClose:nil];
      }
      [NSApp hide:nil];
    } else {
      [_window makeKeyAndOrderFront:nil];
    }
  } else {
    [NSApp activateIgnoringOtherApps:YES];
  }
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
