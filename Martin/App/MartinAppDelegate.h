//
//  MartinAppDelegate.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Player.h"
#import "LibraryOutlineViewManager.h"
#import "PlaylistTableManager.h"
#import "PlaylistManager.h"
#import "PreferencesWindowController.h"
#import "FilePlayer.h"

@interface MartinAppDelegate : NSObject

+ (MartinAppDelegate *)get;

- (void)toggleMartinVisible;

@property (nonatomic, strong) IBOutlet NSWindow *window;

@property (nonatomic, strong) IBOutlet PreferencesWindowController *preferencesWindowController;
@property (nonatomic, strong) IBOutlet Player *player;
@property (nonatomic, strong) IBOutlet LibraryOutlineViewManager *libraryOutlineViewManager;
@property (nonatomic, strong) IBOutlet PlaylistTableManager *playlistTableManager;
@property (nonatomic, strong) IBOutlet PlaylistManager *playlistManager;
@property (nonatomic, strong) IBOutlet FilePlayer *filePlayer;

@property (atomic, assign) int martinBusy;

@end
