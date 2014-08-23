//
//  DataSource.h
//  Martin
//
//  Created by Tomislav Grbin on 9/30/11.
//

#import <Foundation/Foundation.h>

@class LibraryOutlineViewDataSource;

@interface LibraryOutlineViewManager : NSObject

- (void)saveState;

@property (nonatomic, strong) IBOutlet NSTextField *searchTextField;

@property (strong) IBOutlet LibraryOutlineViewDataSource *dataSource;

@end
