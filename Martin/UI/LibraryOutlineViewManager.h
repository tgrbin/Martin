//
//  DataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//

#import <Foundation/Foundation.h>

@interface LibraryOutlineViewManager : NSObject <NSOutlineViewDataSource, NSTextFieldDelegate, NSControlTextEditingDelegate, NSMenuDelegate>

- (void)saveState;

@property (nonatomic, strong) IBOutlet NSTextField *searchTextField;

@end
