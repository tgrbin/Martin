//
//  NotificationsGenerator.h
//  Martin
//
//  Created by Tomislav Grbin on 9/27/13.
//
//

#import <Foundation/Foundation.h>

@class PlaylistItem;

@interface NotificationsGenerator : NSObject

+ (NotificationsGenerator *)shared;

- (void)showWithItem:(PlaylistItem *)item;

@end
