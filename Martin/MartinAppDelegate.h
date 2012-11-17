//
//  MartinAppDelegate.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Player, PlaylistManager;

@interface MartinAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSArray *dragFromLibrary;

@property (unsafe_unretained) IBOutlet Player *player;
@property (weak) IBOutlet PlaylistManager *playlistManager;
@property (nonatomic, strong) IBOutlet NSTableView *playlistsTableView;
@property (nonatomic, strong) IBOutlet NSTableView *songsTableView;
@property (nonatomic, strong) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, strong) IBOutlet NSWindow *window;
@property (nonatomic, strong) IBOutlet NSWindowController *preferencesWindowController;

@end
