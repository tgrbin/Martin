//
//  FolderWatcher.m
//  Martin
//
//  Created by Tomislav Grbin on 12/12/12.
//
//

#import "FolderWatcher.h"
#import "LibraryFolder.h"
#import "RescanProxy.h"

@implementation FolderWatcher

static const double eventLatency = 0.3;

static NSString * const kFWEnabledKey = @"kFWEnabledKey";
static NSString * const kFWLastEventKey = @"kFWLastEventKey";

+ (FolderWatcher *)sharedWatcher {
  static FolderWatcher *o = nil;
  if (o == nil) o = [FolderWatcher new];
  return o;
}

- (void)folderListChanged {
  if (_enabled) {
    [self stopWatchingFolders];
    [self startWatchingFolders];
  }
}

- (id)init {
  if (self = [super init]) {
    _enabled = ([[NSUserDefaults standardUserDefaults] objectForKey:kFWEnabledKey] != nil);
    if (_enabled) [self startWatchingFolders];
  }
  return self;
}

- (void)setEnabled:(BOOL)enabled {
  if (enabled) [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kFWEnabledKey];
  else [[NSUserDefaults standardUserDefaults] removeObjectForKey:kFWEnabledKey];
  [[NSUserDefaults standardUserDefaults] synchronize];

  if (_enabled != enabled) {
    if (enabled) [self startWatchingFolders];
    else {
      [[NSUserDefaults standardUserDefaults] removeObjectForKey:kFWLastEventKey];
      [self stopWatchingFolders];
    }
  }

  _enabled = enabled;
}

- (void)startWatchingFolders {
  if ([LibraryFolder libraryFolders].count == 0) return;

  eventStream = FSEventStreamCreate(NULL,
                                    &handleEvent,
                                    NULL,
                                    (CFArrayRef)[LibraryFolder libraryFolders],
                                    [self lastEventId],
                                    eventLatency,
                                    kFSEventStreamCreateFlagNone);

  FSEventStreamScheduleWithRunLoop(eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStart(eventStream);
}

- (FSEventStreamEventId)lastEventId {
  NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:kFWLastEventKey];
  if (n == nil) return kFSEventStreamEventIdSinceNow;
  return [n longLongValue];
}

static void handleEvent(
                       ConstFSEventStreamRef streamRef,
                       void *clientCallBackInfo,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[])
{
  char **paths = eventPaths;

  for (int i = 0; i < numEvents; i++) {
    NSLog(@"Change %llu in %s, flags %d\n", eventIds[i], paths[i], eventFlags[i]&kFSEventStreamEventFlagMustScanSubDirs);
    [[RescanProxy sharedProxy] rescanFolder:@(paths[i])
                                recursively:eventFlags[i]&kFSEventStreamEventFlagMustScanSubDirs];
  }

  [[NSUserDefaults standardUserDefaults] setObject:@(eventIds[numEvents-1]) forKey:kFWLastEventKey];
}

- (void)stopWatchingFolders {
  if (eventStream != nil) {
    FSEventStreamStop(eventStream);
    FSEventStreamInvalidate(eventStream);
    FSEventStreamRelease(eventStream);
    eventStream = nil;
  }
}

@end
