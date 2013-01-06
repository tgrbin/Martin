//
//  DataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LibraryOutlineViewManager : NSObject <NSOutlineViewDataSource, NSTextFieldDelegate, NSControlTextEditingDelegate, NSMenuDelegate>

+ (LibraryOutlineViewManager *)sharedManager;

@property (nonatomic, strong) IBOutlet NSOutlineView *outlineView;

@property (assign) IBOutlet NSView *rescanStatusView;
@property (assign) IBOutlet NSProgressIndicator *rescanIndicator;
@property (assign) IBOutlet NSTextField *rescanMessage;
@property (assign) IBOutlet NSProgressIndicator *determinateRescanIndicator;

@property (assign) IBOutlet NSTextField *searchTextField;

@end
