//
//  MartinAppDelegate.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//

#import "MartinAppDelegate.h"
#import "GlobalShortcuts.h"
#import "PlaylistNameGuesser.h"
#import "DefaultsManager.h"
#import "FileExtensionChecker.h"
#import "PlayerStatusTextField.h"
#import "FolderWatcher.h"
#import "MediaKeysManager.h"
#import "PlaylistFile.h"
#import "Playlist.h"

@interface MartinAppDelegate() <NSApplicationDelegate, NSWindowDelegate>
@property (nonatomic, strong) IBOutlet NSProgressIndicator *martinBusyIndicator;

@property (nonatomic, strong) IBOutlet NSBox *middleControlsView;
@property (nonatomic, strong) IBOutlet NSBox *rightControlsView;
@property (nonatomic, strong) IBOutlet NSView *contentView;
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

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  [_tabsManager allLoaded];
  [_playerController restorePlayerState];
  [FolderWatcher sharedWatcher];
  [MediaKeysManager shared];
}

- (void)applicationWillBecomeActive:(NSNotification *)notification {
  if (_window.isVisible == NO) {
    [_window makeKeyAndOrderFront:nil];
  }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  [_tabsManager savePlaylists];
  [_libraryOutlineViewManager saveState];
  [_playerController storePlayerState];
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
    [_tabsManager selectNowPlayingPlaylist];
  }
}

#pragma mark - opening external files

- (IBAction)openPressed:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseDirectories = YES;
  panel.canChooseFiles = YES;
  panel.allowsMultipleSelection = YES;
  panel.allowedFileTypes = [[FileExtensionChecker acceptableExtensions] arrayByAddingObjectsFromArray:[PlaylistFile supportedFileFormats]];
  panel.title = @"Open...";
  
  if ([panel runModal] == NSFileHandlingPanelOKButton) {
    NSMutableArray *filenames = [NSMutableArray new];
    for (NSURL *url in panel.URLs) [filenames addObject:[url path]];
    [self openFilesAndFolders:filenames];
  }
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  [self openFilesAndFolders:@[filename]];
  return NO;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
  [self openFilesAndFolders:filenames];
  [[NSApplication sharedApplication] replyToOpenOrPrint:NSApplicationDelegateReplyCancel];
}

- (void)openFilesAndFolders:(NSArray *)filesAndFolders {
  // if all selected files are playlists, add each of them as a separate playlist
  // otherwise, traverse everything and append files to the current playlist
  
  // TODO: currently, you can't select a folder containing playlists
  // only one or more playlists can be selected directly as files, not as folders containing them
  
  BOOL onlyPlaylists = YES;
  for (NSString *filename in filesAndFolders) {
    // warning: if a folder has a name ending with .m3u it will pass isFileAPlaylist
    if ([PlaylistFile isFileAPlaylist:filename] == NO) {
      onlyPlaylists = NO;
      break;
    }
  }
  
  if (onlyPlaylists) {
    for (NSString *playlistFilename in filesAndFolders) {
      PlaylistFile *playlistFile = [PlaylistFile playlistFileWithFilename:playlistFilename];
      NSString *playlistName = [[playlistFilename lastPathComponent] stringByDeletingPathExtension];
      [playlistFile loadWithBlock:^(NSArray *playlistItems) {
        [_tabsManager addNewPlaylistWithPlaylistItems:playlistItems
                                              andName:playlistName];
      }];
    }
  } else {
    [PlaylistNameGuesser itemsAndNameFromFolders:filesAndFolders withBlock:^(NSArray *items, NSString *name) {
      if (items.count > 0) {
        if (_playerController.nowPlayingPlaylist) {
          [_playlistTableManager addPlaylistItems:items];
        } else {
          [_tabsManager addNewPlaylistWithPlaylistItems:items andName:name];
        }
      }
    }];
  }
}

- (IBAction)savePlaylistPressed:(id)sender {
  Playlist *playlist = _tabsManager.selectedPlaylist;
  
  if (playlist) { // shouldn't ever be nil, but still..
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedFileTypes = [PlaylistFile supportedFileFormats];
    panel.canCreateDirectories = YES;
    panel.title = @"Save Playlist";
    panel.nameFieldStringValue = playlist.name;
    
    if ([panel runModal] == NSFileHandlingPanelOKButton) {
      NSString *filename = panel.URL.path;
      PlaylistFile *playlistFile = [PlaylistFile playlistFileWithFilename:filename];
      if (![playlistFile savePlaylist:playlist]) {
        NSString *errorMessage = [NSString stringWithFormat:@"Sorry, couldn't save playlist:\n'%@'", filename];
        NSAlert *alert = [NSAlert alertWithMessageText:errorMessage
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        [alert runModal];
      }
    }
  }
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
  
  [_middleControlsView removeFromSuperview];
  _middleControlsView.frame = NSMakeRect((_contentView.frame.size.width - _middleControlsView.frame.size.width) / 2,
                                         _contentView.frame.size.height + 4,
                                         _middleControlsView.frame.size.width,
                                         60);
  [_contentView.superview addSubview:_middleControlsView];
}

@end
