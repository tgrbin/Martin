//
//  TabsManager.h
//  Martin
//
//  Created by Tomislav Grbin on 9/21/13.
//
//

#import <Foundation/Foundation.h>

@class QueuePlaylist;

@interface TabsManager : NSObject

@property (nonatomic, strong) QueuePlaylist *queue;
- (void)showQueueTab;
- (void)hideQueueTab;
- (void)refreshQueueObjectCount;

@end
