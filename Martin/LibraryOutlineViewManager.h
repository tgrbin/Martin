//
//  DataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LibraryOutlineViewManager : NSObject <NSOutlineViewDataSource, NSTextFieldDelegate, NSControlTextEditingDelegate, NSMenuDelegate>

- (void)saveState;

@end
