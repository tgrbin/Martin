//
//  LibraryOutlineViewDataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import <Foundation/Foundation.h>

@interface LibraryOutlineViewDataSource : NSObject

- (NSInteger)numberOfChildrenOfItem:(id)item;
- (id)childAtIndex:(NSInteger)index ofItem:(id)item;

- (BOOL)isItemLeaf:(id)item;
- (id)parentOfItem:(id)item;
- (BOOL)isItemFromLibrary:(id)item;

@end
