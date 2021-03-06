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
#import "TabsManager.h"
#import "StreamsController.h"

@interface MartinAppDelegate : NSObject

+ (MartinAppDelegate *)get;

- (void)toggleMartinVisible;

@property (nonatomic, strong) IBOutlet NSWindow *window;

@property (nonatomic, strong) IBOutlet PreferencesWindowController *preferencesWindowController;
@property (nonatomic, strong) IBOutlet PlayerController *playerController;
@property (nonatomic, strong) IBOutlet LibraryOutlineViewManager *libraryOutlineViewManager;
@property (nonatomic, strong) IBOutlet PlaylistTableManager *playlistTableManager;
@property (nonatomic, strong) IBOutlet TabsManager *tabsManager;
@property (nonatomic, strong) IBOutlet StreamsController *streamsController;

@property (atomic, assign) int martinBusy;

@end
