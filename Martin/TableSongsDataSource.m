//
//  TableSongsDataSource.m
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TableSongsDataSource.h"
#import "MartinAppDelegate.h"
#import "PlaylistManager.h"
#import "LibManager.h"
#import "TreeNode.h"
#import "Playlist.h"
#import "Song.h"

@implementation TableSongsDataSource

@synthesize table, deleteButton;
@synthesize dragRows, appDelegate;
@synthesize playlist, sortedColumn, sortAscending;

#pragma mark - init

- (void)awakeFromNib {
    highlighted = -1;
    prevHighlighted = -1;
    [table registerForDraggedTypes:[NSArray arrayWithObject:@"MyDragType"]];
}

#pragma mark - drag and drop

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
    [pboard declareTypes:[NSArray arrayWithObject:@"MyDragType"] owner:nil];
    [pboard setData:[NSData data] forType:@"MyDragType"];
    
    self.dragRows = rows;
    
    return YES;        
}

- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    
    if( [info draggingSource] != appDelegate.outlineView && [info draggingSource] != tableView ) {
        return NSDragOperationNone;
    } else {
        [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
        return NSDragOperationCopy;
    }
}

- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    
    if( [info draggingSource] == appDelegate.outlineView ) {

        [playlist addSongs:appDelegate.dragFromLibrary atPos:row];

    } else if( [info draggingSource] == tableView ) {
    
        int newPos = [playlist reorderSongs:self.dragRows atPos: row];
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(newPos, [self.dragRows count])] byExtendingSelection:NO];
         
    } else return NO;
    
    [tableView reloadData];
    return YES;
}

#pragma mark - delegate

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
    if( sortedColumn == tableColumn ) {
        sortAscending = !sortAscending;
        [playlist reverse];
    } else {
        sortAscending = YES;
        
        if( sortedColumn ) [tableView setIndicatorImage:nil inTableColumn: sortedColumn];
        self.sortedColumn = tableColumn;
        
        [tableView setHighlightedTableColumn: tableColumn];
        [playlist sortBy:tableColumn.identifier];
    }
    
    [tableView setIndicatorImage: [NSImage imageNamed: sortAscending? @"NSAscendingSortIndicator": @"NSDescendingSortIndicator"] inTableColumn:tableColumn];
    [tableView reloadData];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)c forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTextFieldCell *cell = (NSTextFieldCell*)c;
    
    if( [[playlist.songs objectAtIndex:row] intValue] == highlighted ) {
        cell.drawsBackground = YES;
        cell.backgroundColor = [NSColor colorWithCalibratedRed:0.6 green:0.7 blue:0.8 alpha:1.0];
    } else {
        cell.drawsBackground = NO;
    }
}

#pragma mark - data source

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
    return [playlist.songs count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *tag = [tableColumn identifier];
    int songID = [[playlist.songs objectAtIndex:row] intValue];
    Song *song = [LibManager songByID:songID];
    
    return [song valueForKey:tag];
    
    return @"unknown";
}

- (IBAction)buttonPressed:(id)sender { // delete je jedini button
    NSInteger n = [table numberOfRows];
    NSInteger m = [[table selectedRowIndexes] count];
    NSUInteger selectRow = [[table selectedRowIndexes] lastIndex];

    if( m > 0 ) {
        [self.playlist removeSongsAtIndexes:[table selectedRowIndexes]];
        [table deselectAll:nil];
        [table reloadData];
        
        if( selectRow < n-1 ) selectRow = selectRow-m+1;
        else selectRow = n-m-1;
        
        [table selectRowIndexes:[NSIndexSet indexSetWithIndex:selectRow] byExtendingSelection:NO];
        [table scrollRowToVisible:selectRow];
    }
}

#pragma mark - highlight now playing

- (void) highlightSong:(int)_id {
    NSIndexSet *columns = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 4)];
        
    prevHighlighted = highlighted;
    highlighted = _id;
    
    NSMutableIndexSet *rows = [NSMutableIndexSet indexSet];
    
    if( prevHighlighted >= 0 ) [rows addIndex:[playlist.songs indexOfObject:[NSNumber numberWithInt:prevHighlighted]]];
    if( highlighted >= 0 ) [rows addIndex:[playlist.songs indexOfObject:[NSNumber numberWithInt:highlighted]]];

    [table reloadDataForRowIndexes:rows columnIndexes:columns];
}

@end
