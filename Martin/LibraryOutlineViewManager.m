//
//  DataSource.m
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LibraryOutlineViewManager.h"
#import "LibManager.h"
#import "TreeNode.h"
#import "TreeLeaf.h"

@implementation LibraryOutlineViewManager

static LibraryOutlineViewManager *sharedManager;

+ (LibraryOutlineViewManager *)sharedManager {
  return sharedManager;
}

- (void)awakeFromNib {
  sharedManager = self;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(libraryRescanFinished)
                                               name:kLibManagerRescanedLibraryNotification
                                             object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - drag and drop

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
  [pboard declareTypes:@[@"MyDragType"] owner:nil];
  [pboard setData:[NSData data] forType:@"MyDragType"];
  _draggingItems = items;
  return YES;
}

- (void)libraryRescanFinished {
  [_outlineView reloadData];
}

#pragma mark - data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (item == nil) return [[LibManager sharedManager].treeRoot nChildren];
  return [item nChildren];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  if (item == nil) return [[LibManager sharedManager].treeRoot getChild:index];
  return [item getChild:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  if (item == nil) return YES;
  return [item nChildren] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if (item == nil) return @"root";
  if ([item nChildren] == 0) return [item name];
  return [NSString stringWithFormat:@"%@ (%d)", [item name], [item nChildren]];
}

#pragma mark - search

- (IBAction)search:(NSTextField *)sender {
  [[LibManager sharedManager] performSearch:sender.stringValue];
  [_outlineView reloadData];
}

@end
