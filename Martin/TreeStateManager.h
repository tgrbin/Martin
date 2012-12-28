//
//  TreeStateManager.h
//  Martin
//
//  Created by Tomislav Grbin on 12/28/12.
//
//

#import <Foundation/Foundation.h>

@interface TreeStateManager : NSObject

+ (void)saveState;
+ (void)restoreState;

@end
