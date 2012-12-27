//
//  FolderWatcher.h
//  Martin
//
//  Created by Tomislav Grbin on 12/12/12.
//
//

#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>

@interface FolderWatcher : NSObject

+ (FolderWatcher *)sharedWatcher;

@property (nonatomic, assign) BOOL enabled;

- (void)folderListChanged;
- (void)storeLastEventId;

@end
