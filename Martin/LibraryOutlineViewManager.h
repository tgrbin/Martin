//
//  DataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LibraryOutlineViewManager : NSObject <NSOutlineViewDataSource, NSTextFieldDelegate, NSControlTextEditingDelegate, NSMenuDelegate> {
  BOOL reloadingTree;
}

+ (LibraryOutlineViewManager *)sharedManager;

@property (nonatomic, strong) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, strong) NSArray *draggingItems;
@property (weak) IBOutlet NSView *rescanStatusView;
@property (weak) IBOutlet NSProgressIndicator *rescanIndicator;
@property (weak) IBOutlet NSTextField *rescanMessage;

@end
