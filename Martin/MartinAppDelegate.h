//
//  MartinAppDelegate.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Player, PlaylistManager;

@interface MartinAppDelegate : NSObject <NSApplicationDelegate> {
    NSArray *dragFromLibrary;
}

@property (nonatomic, retain) NSArray *dragFromLibrary;

@property (assign) IBOutlet Player *player;
@property (assign) IBOutlet PlaylistManager *playlistManager;
@property (nonatomic, retain) IBOutlet NSTableView *playlistsTableView;
@property (nonatomic, retain) IBOutlet NSTableView *songsTableView;
@property (nonatomic, retain) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, retain) IBOutlet NSWindow *window;

@end
