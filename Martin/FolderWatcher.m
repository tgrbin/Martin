//
//  FolderWatcher.m
//  Martin
//
//  Created by Tomislav Grbin on 12/12/12.
//
//

#import "FolderWatcher.h"
#import "LibraryFolder.h"

@implementation FolderWatcher

static NSString * const kFWEnabledKey = @"fwenabledkey";

+ (FolderWatcher *)sharedWatcher {
  static FolderWatcher *o = nil;
  if (o == nil) o = [[FolderWatcher alloc] init];
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
    else [self stopWatchingFolders];
  }

  _enabled = enabled;
}

- (void)startWatchingFolders {
  NSMutableArray *paths = [NSMutableArray array];
  for (LibraryFolder *lf in [LibraryFolder libraryFolders]) {
    [paths addObject:lf.folderPath];
  }

  if (paths.count == 0) return;

  eventStream = FSEventStreamCreate(NULL,
                                    &handleEvent,
                                    NULL,
                                    (CFArrayRef)paths,
                                    kFSEventStreamEventIdSinceNow,
                                    1.0, // latency
                                    kFSEventStreamCreateFlagNone);

  FSEventStreamScheduleWithRunLoop(eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStart(eventStream);
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
  }
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
