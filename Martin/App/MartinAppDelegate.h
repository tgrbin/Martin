//
//  MartinAppDelegate.h
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//

#import <Cocoa/Cocoa.h>
#import "PlayerController.h"
#import "LibraryOutlineViewManager.h"
#import "PlaylistTableManager.h"
#import "PreferencesWindowController.h"
#import "FilePlayer.h"
#import "TabsManager.h"

@interface MartinAppDelegate : NSObject

+ (MartinAppDelegate *)get;

- (void)toggleMartinVisible;

@property (nonatomic, strong) IBOutlet NSWindow *window;

@property (nonatomic, strong) IBOutlet PreferencesWindowController *preferencesWindowController;
@property (nonatomic, strong) IBOutlet PlayerController *playerController;
@property (nonatomic, strong) IBOutlet LibraryOutlineViewManager *libraryOutlineViewManager;
@property (nonatomic, strong) IBOutlet PlaylistTableManager *playlistTableManager;
@property (nonatomic, strong) IBOutlet FilePlayer *filePlayer;
@property (nonatomic, strong) IBOutlet TabsManager *tabsManager;

@property (atomic, assign) int martinBusy;

@end
