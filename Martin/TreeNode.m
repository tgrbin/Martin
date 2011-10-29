//
//  TreeNode.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TreeNode.h"

@implementation TreeNode

@synthesize name, children, searchState;

- (id)initWithName:(NSString *)s {
    if( self = [super init] ) {
        children = [[NSMutableArray alloc] init];
        results = [[NSMutableArray alloc] init];
        name = [s retain];
        searchState = 0;
    }
    return self;
}

- (id)init {
    return [self initWithName:@"unknown"];
}

- (int)nChildren {    
    if( searchState == 0 ) return 0;
    
    if( searchState == 1 ) {
        [self clearResults];
        for( TreeNode *c in children )
            if( c.searchState > 0 ) [self addResult:c];
        searchState = 4;
    }
    
    if( searchState == 2 ) {
        for( TreeNode *c in children )
            c.searchState = 2;
        searchState = 3;
    }

    return searchState == 3? (int)[children count]: (int)[results count];
}

- (TreeNode*)getChild:(NSInteger) index {    
    return searchState == 3? [children objectAtIndex:index]: [results objectAtIndex:index];
}

- (void)addChild:(TreeNode*) child {
    [children addObject:child];
}

- (void)clearResults {
    [results removeAllObjects];
}

- (void)addResult:(TreeNode*) res {
    [results addObject:res];
}

- (void)dealloc {
    [children release];
    [results release];
    [name release];
    [super dealloc];
}

@end
