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
@synthesize appDelegate;

@synthesize table, deleteButton;
@synthesize playlist, dragRows;

#pragma mark - init

- (void)awakeFromNib {
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

#pragma mark - data source

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
    return [playlist.songs count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSString *tag = [tableColumn identifier];
    int songID = [[playlist.songs objectAtIndex:row] intValue];
    Song *song = [LibManager songByID:songID];
    
    if( [tag isEqualToString:@"track"] ) return song.trackNumber;
    if( [tag isEqualToString:@"artist"] ) return song.artist;
    if( [tag isEqualToString:@"title"] ) return song.title;
    if( [tag isEqualToString:@"album"] ) return song.album;
    
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

@end
