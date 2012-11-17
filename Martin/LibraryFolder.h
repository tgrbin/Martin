//
//  LibraryFolders.h
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import <Foundation/Foundation.h>

@interface LibraryFolder : NSObject

@property (nonatomic, strong) NSString *folderPath;
@property (nonatomic, strong) NSString *treeDisplayName;

+ (NSMutableArray *)libraryFolders;
+ (void)save;

@end
