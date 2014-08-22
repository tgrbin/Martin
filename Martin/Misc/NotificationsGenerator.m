//
//  NotificationsGenerator.m
//  Martin
//
//  Created by Tomislav Grbin on 9/27/13.
//
//

#import "NotificationsGenerator.h"
#import "PlaylistItem.h"

@implementation NotificationsGenerator

static NotificationsGenerator *instance;

+ (void)initialize {
  instance = [NotificationsGenerator new];
}

+ (NotificationsGenerator *)shared {
  return instance;
}

- (void)showWithItem:(PlaylistItem *)item {
  if (NSClassFromString(@"NSUserNotification") == nil) {
    return;
  }

  // TODO: handle stream meta data correctly!
  
  NSString *title = [item tagValueForIndex:kTagIndexTitle];
  NSString *subtitle = nil;
  if (title.length > 0) {
    NSMutableArray *arr = [NSMutableArray new];
    NSString *artist = [item tagValueForIndex:kTagIndexArtist];
    NSString *album = [item tagValueForIndex:kTagIndexAlbum];
    if (artist.length) [arr addObject:artist];
    if (album.length) [arr addObject:album];
    subtitle = [arr componentsJoinedByString:@" - "];
  } else {
    title = [[item.filename lastPathComponent] stringByDeletingPathExtension];
    subtitle = [[item.filename stringByDeletingLastPathComponent] lastPathComponent];
  }

  NSUserNotification *notification = [NSUserNotification new];
  notification.title = title;
  notification.subtitle = subtitle;
  [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

@end
