//
//  FolderWatcher.h
//  Martin
//
//  Created by Tomislav Grbin on 12/12/12.
//
//

#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>

@interface FolderWatcher : NSObject {
  FSEventStreamRef eventStream;
}

+ (FolderWatcher *)sharedWatcher;

@property (nonatomic, assign) BOOL enabled;

- (void)folderListChanged;

@end
