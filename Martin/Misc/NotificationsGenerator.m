//
//  NotificationsGenerator.m
//  Martin
//
//  Created by Tomislav Grbin on 9/27/13.
//
//

#import "NotificationsGenerator.h"
#import "PlaylistItem.h"

#import "STKHTTPDataSource.h"
#import "NSObject+Observe.h"

@interface NotificationsGenerator()

@property (nonatomic, copy) NSString *currentStreamName;

@end

@implementation NotificationsGenerator

static NotificationsGenerator *instance;

+ (void)initialize {
  instance = [NotificationsGenerator new];
  [instance observe:kGotNewMetaDataNotification
         withAction:@selector(gotNewMetaData:)];
}

+ (NotificationsGenerator *)shared {
  return instance;
}

- (void)showWithItem:(PlaylistItem *)item {
  NSString *title = [item tagValueForIndex:kTagIndexTitle];
  NSString *subtitle = nil;

  if (item.isURLStream == YES) {
    self.currentStreamName = title;
  } else {
    self.currentStreamName = nil;
    
    if (title.length > 0) {
      NSMutableArray *arr = [NSMutableArray new];
      
      NSString *artist = [item tagValueForIndex:kTagIndexArtist];
      if (artist.length > 0) {
        [arr addObject:artist];
      }
      
      NSString *album = [item tagValueForIndex:kTagIndexAlbum];
      if (album.length > 0) {
        [arr addObject:album];
      }
      
      subtitle = [arr componentsJoinedByString:@" - "];
    } else {
      title = [[item.filename lastPathComponent] stringByDeletingPathExtension];
      subtitle = [[item.filename stringByDeletingLastPathComponent] lastPathComponent];
    }
  }
  
  [self showNotificationWithTitle:title
                      andSubtitle:subtitle];
}

- (void)gotNewMetaData:(NSNotification *)notification {
  NSString *text = notification.userInfo[@"streamTitle"];
  [self showNotificationWithTitle:self.currentStreamName
                      andSubtitle:text];
}

- (void)showNotificationWithTitle:(NSString *)title
                      andSubtitle:(NSString *)subtitle
{
  if (NSClassFromString(@"NSUserNotification") == nil) {
    return;
  }
  
  NSUserNotification *notification = [NSUserNotification new];
  notification.title = title;
  notification.subtitle = subtitle;
  [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

@end
