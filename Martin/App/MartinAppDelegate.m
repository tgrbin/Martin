//
//  MartinAppDelegate.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MartinAppDelegate.h"
#import "GlobalShortcuts.h"
#import "PlaylistNameGuesser.h"
#import "DefaultsManager.h"

@interface MartinAppDelegate()
@property (strong) IBOutlet NSProgressIndicator *martinBusyIndicator;
@end

@implementation MartinAppDelegate

@synthesize martinBusy = _martinBusy;

+ (void)initialize {
  [GlobalShortcuts setupShortcuts];
}

+ (MartinAppDelegate *)get {
  return (MartinAppDelegate *)[[NSApplication sharedApplication] delegate];
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

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  [_playlistManager savePlaylists];
  [_libraryOutlineViewManager saveState];
  [_filePlayer storeVolume];
  return YES;
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

#pragma mark - opening external files

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  [self addFoldersToPlaylist:@[filename]];
  return NO;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
  [self addFoldersToPlaylist:filenames];
  [[NSApplication sharedApplication] replyToOpenOrPrint:NSApplicationDelegateReplyCancel];
}

- (void)addFoldersToPlaylist:(NSArray *)folders {
  [PlaylistNameGuesser itemsAndNameFromFolders:folders withBlock:^(NSArray *items, NSString *name) {
    if (items.count > 0) {
      if (_player.nowPlayingPlaylist) {
        [_playlistTableManager addPlaylistItems:items];
      } else {
        [_playlistManager addNewPlaylistWithPlaylistItems:items andName:name];
      }
    }
  }];
}

#pragma mark - martin busy indicator

- (int)martinBusy {
  @synchronized (self) {
    return _martinBusy;
  }
}

- (void)setMartinBusy:(int)martinBusy {
  @synchronized (self) {
    _martinBusy = martinBusy;

    [_martinBusyIndicator setHidden:martinBusy == 0];

    if (martinBusy > 0) {
      [_martinBusyIndicator startAnimation:nil];
    } else {
      [_martinBusyIndicator stopAnimation:nil];
    }
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"operationCount"]) {
    int oldVal = [[change objectForKey:NSKeyValueChangeOldKey] intValue];
    int newVal = [[change objectForKey:NSKeyValueChangeNewKey] intValue];

    if (newVal%100 == 0) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [_playlistTableManager reloadTableData];
      });
    }

    if (oldVal == 0 && newVal > 0) ++self.martinBusy;
    if (oldVal > 0 && newVal == 0) --self.martinBusy;
  }
}

#pragma mark - first run

- (void)windowDidBecomeKey:(NSNotification *)notification {
  _window.delegate = nil;
  [self checkForFirstRun];
}

- (void)checkForFirstRun {
  if ([[DefaultsManager objectForKey:kDefaultsKeyFirstRun] boolValue] == YES) {
    [DefaultsManager setObject:@NO forKey:kDefaultsKeyFirstRun];

    NSAlert *alert = [NSAlert alertWithMessageText:@"Hi! I'll need to know where is your music."
                                     defaultButton:@"Choose folders now"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@""];

    if ([alert runModal] == NSAlertDefaultReturn) {
      [_preferencesWindowController showWindow:nil];
      [_preferencesWindowController showAddFolder];
    }
  }
}

@end
