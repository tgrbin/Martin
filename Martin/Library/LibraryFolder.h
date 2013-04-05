//
//  LibraryFolders.h
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import <Foundation/Foundation.h>

@interface LibraryFolder : NSObject

+ (NSMutableArray *)libraryFolders;
+ (void)save;

@end
