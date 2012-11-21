//
//  TableSongsDataSource.m
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TableSongsDataSource.h"
#import "MartinAppDelegate.h"
#import "LibManager.h"
#import "TreeNode.h"
#import "Playlist.h"
#import "PlaylistItem.h"

@interface TableSongsDataSource()
@property (nonatomic, assign) int highlightedRow;
@end

@implementation TableSongsDataSource

#pragma mark - init

- (void)awakeFromNib {
  _highlightedRow = -1;
  [table registerForDraggedTypes:@[@"MyDragType"]];
}

#pragma mark - drag and drop

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  [pboard declareTypes:@[@"MyDragType"] owner:nil];
  [pboard setData:[NSData data] forType:@"MyDragType"];
  dragRows = rows;
  return YES;        
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  if (info.draggingSource != appDelegate.outlineView && info.draggingSource != tableView) {
    return NSDragOperationNone;
  } else {
    [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
    return NSDragOperationCopy;
  }
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
  if (info.draggingSource == appDelegate.outlineView) {
    [_playlist addTreeNodes:appDelegate.dragFromLibrary atPos:(int)row];
  } else if (info.draggingSource == tableView) {
    int newPos = [_playlist reorderSongs:dragRows atPos:(int)row];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(newPos, dragRows.count)] byExtendingSelection:NO];
  } else {
    return NO;
  }
  
  [tableView reloadData];
  return YES;
}

#pragma mark - delegate

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
  if (_sortedColumn == tableColumn) {
    sortAscending = !sortAscending;
    [_playlist reverse];
  } else {
    sortAscending = YES;
    
    if (_sortedColumn) [tableView setIndicatorImage:nil inTableColumn:_sortedColumn];
    self.sortedColumn = tableColumn;
    
    [tableView setHighlightedTableColumn:tableColumn];
    [_playlist sortBy:tableColumn.identifier];
  }
  
  [tableView setIndicatorImage:[NSImage imageNamed: sortAscending? @"NSAscendingSortIndicator": @"NSDescendingSortIndicator"] inTableColumn:tableColumn];
  [tableView reloadData];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)c forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTextFieldCell *cell = (NSTextFieldCell*)c;
  
  if (_showingNowPlayingPlaylist && row == _highlightedRow) {
    cell.drawsBackground = YES;
    cell.backgroundColor = [NSColor colorWithCalibratedRed:0.6 green:0.7 blue:0.8 alpha:1.0];
  } else {
    cell.drawsBackground = NO;
  }
}

#pragma mark - data source

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
  return _playlist.numberOfItems;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSString *tag = tableColumn.identifier;
  PlaylistItem *item = _playlist[(int)row];
  NSString *value = [item.tags objectForKey:tag];
  
  if ([tag isEqualToString:@"length"]) {
    int sec = item.lengthInSeconds;
    value = [NSString stringWithFormat:@"%d:%02d", sec/60, sec%60];
  }
  
  return value;
}

- (IBAction)deleteSongsPressed:(NSButton *)sender {
  NSIndexSet *selectedIndexes = table.selectedRowIndexes;
  int n = (int)table.numberOfRows;
  int m = (int)selectedIndexes.count;
  int selectRow = (int)selectedIndexes.lastIndex;

  if (m > 0) {
    [self.playlist removeSongsAtIndexes:selectedIndexes];
    [table deselectAll:nil];
    [table reloadData];
    
    selectRow = (selectRow < n-1)? selectRow-m+1: n-m-1;
    
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:selectRow] byExtendingSelection:NO];
    [table scrollRowToVisible:selectRow];
  }
}

#pragma mark - update now playing

- (void)playingItemChanged {
  self.highlightedRow = _playlist.currentItemIndex;
}

- (void)setHighlightedRow:(int)highlightedRow {
  static int previousHighlightedRow;
  previousHighlightedRow = _highlightedRow;
  _highlightedRow = highlightedRow;
  
  NSMutableIndexSet *rows = [NSMutableIndexSet indexSet];
  if (previousHighlightedRow >= 0) [rows addIndex:previousHighlightedRow];
  if (highlightedRow >= 0) [rows addIndex:highlightedRow];
  NSIndexSet *columns = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, table.numberOfColumns)];
  [table reloadDataForRowIndexes:rows columnIndexes:columns];
}

@end
