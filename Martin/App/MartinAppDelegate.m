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
#import "FileExtensionChecker.h"

@interface MartinAppDelegate() <NSApplicationDelegate, NSWindowDelegate>
@property (nonatomic, strong) IBOutlet NSProgressIndicator *martinBusyIndicator;
@property (nonatomic, strong) IBOutlet NSBox *rightControlsView;
@property (nonatomic, unsafe_unretained) IBOutlet NSView *contentView;
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
  BOOL showedMartin = NO;
  if (inForeground) {
    if (isVisible == YES) {
      [_window performClose:nil];
      if ([_preferencesWindowController isWindowLoaded] && _preferencesWindowController.window.isVisible == YES) {
        [_preferencesWindowController.window performClose:nil];
      }
      [NSApp hide:nil];
    } else {
      [_window makeKeyAndOrderFront:nil];
      showedMartin = YES;
    }
  } else {
    showedMartin = YES;
    [NSApp activateIgnoringOtherApps:YES];
  }

  if (showedMartin) {
    [_playlistManager selectNowPlayingPlaylist];
  }
}

#pragma mark - opening external files

- (IBAction)openPressed:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseDirectories = YES;
  panel.canChooseFiles = YES;
  panel.allowsMultipleSelection = YES;
  panel.allowedFileTypes = [FileExtensionChecker acceptableExtensions];
  panel.title = @"Open";

  if ([panel runModal] == NSFileHandlingPanelOKButton) {
    NSMutableArray *filenames = [NSMutableArray new];
    for (NSURL *url in panel.URLs) [filenames addObject:[url path]];
    [self addFoldersToPlaylist:filenames];
  }
}

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

#pragma mark - placing controls above titlebar

- (void)awakeFromNib {
  [_rightControlsView removeFromSuperview];
  _rightControlsView.frame = NSMakeRect(_contentView.frame.size.width - _rightControlsView.frame.size.width,
                                        _contentView.frame.size.height + 3,
                                        _rightControlsView.frame.size.width,
                                        60);
  [_contentView.superview addSubview:_rightControlsView];

}

@end
