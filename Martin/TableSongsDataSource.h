//
//  TableSongsDataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Playlist, MartinAppDelegate;

@interface TableSongsDataSource : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
  int highlighted;
  int prevHighlighted;
}

@property (weak) Playlist *playlist;
@property (nonatomic, strong) NSTableColumn *sortedColumn; // stupac koji je sortiran
@property (nonatomic, assign) BOOL sortAscending;

@property (nonatomic, strong) NSArray *dragRows;

@property (weak) IBOutlet MartinAppDelegate *appDelegate;
@property (nonatomic, strong) IBOutlet NSTableView *table;
@property (nonatomic, strong) IBOutlet NSButton *deleteButton;

- (IBAction) buttonPressed:(id)sender;
- (void) highlightSong:(int)_id;

@end
