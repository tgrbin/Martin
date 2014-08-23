//
//  LibraryTreeOutlineViewState.h
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import <Foundation/Foundation.h>

@interface LibraryTreeOutlineViewState : NSObject

+ (void)storeInodesAndLevelsForNodes:(NSSet *)nodes;
+ (void)restoreNodesForStoredInodesAndLevelsToSet:(NSMutableSet *)set;

@end
