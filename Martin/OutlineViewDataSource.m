//
//  DataSource.m
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OutlineViewDataSource.h"
#import "MartinAppDelegate.h"
#import "LibManager.h"
#import "TreeNode.h"
#import "TreeLeaf.h"

@implementation OutlineViewDataSource
@synthesize outline, textField;

#pragma mark - drag and drop

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    [pboard declareTypes:[NSArray arrayWithObject:@"MyDragType"] owner:nil];
    [pboard setData:[NSData data] forType:@"MyDragType"];
    
    ((MartinAppDelegate*) [[NSApplication sharedApplication] delegate]).dragFromLibrary = items;

    return YES;
}

#pragma mark - data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if( item == nil ) return [[LibManager getRoot] nChildren];
    
    return [item nChildren];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if( item == nil ) return [[LibManager getRoot] getChild:index];
    
    return [item getChild:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if( item == nil ) return YES;
    
    return [item nChildren] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *) tableColumn byItem:(id)item {
    if( item == nil ) return @"root";
    
    if( [item nChildren] == 0 ) return [item name];
    return [NSString stringWithFormat:@"%@ (%d)", [item name], [item nChildren]];
}

#pragma mark - search

- (IBAction)search:(id)sender {
    [LibManager search:[sender stringValue]];
    [outline reloadData];
}

@end
