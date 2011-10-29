//
//  TableSongsDataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Playlist, MartinAppDelegate;

@interface TableSongsDataSource : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, retain) NSArray *dragRows;
@property (assign) Playlist *playlist;

@property (assign) IBOutlet MartinAppDelegate *appDelegate;
@property (nonatomic, retain) IBOutlet NSTableView *table;
@property (nonatomic, retain) IBOutlet NSButton *deleteButton;

- (IBAction)buttonPressed:(id)sender;

@end
