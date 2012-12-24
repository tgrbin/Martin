//
//  RescanProxy.h
//  Martin
//
//  Created by Tomislav Grbin on 12/24/12.
//
//

#import <Foundation/Foundation.h>

@interface RescanProxy : NSObject

+ (RescanProxy *)sharedProxy;

- (void)rescanAll;
- (void)rescanFolder:(NSString *)folderPath recursively:(BOOL)recursively;
- (void)rescanRecursivelyTreeNodes:(NSArray *)treeNodes;

@end
