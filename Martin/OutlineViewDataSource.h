//
//  DataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OutlineViewDataSource : NSObject <NSOutlineViewDataSource>

@property (nonatomic, retain) IBOutlet NSOutlineView *outline;
@property (nonatomic, retain) IBOutlet NSTextField *textField;

- (IBAction)search:(id)sender;

@end
