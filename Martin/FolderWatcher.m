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
#import "DefaultsManager.h"

@implementation FolderWatcher {
  FSEventStreamRef eventStream;
}

static const double eventLatency = 0.3;

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
    _enabled = [[DefaultsManager objectForKey:kDefaultsKeyFolderWatcher] boolValue];
    if (_enabled) [self startWatchingFolders];
  }
  return self;
}

- (void)setEnabled:(BOOL)enabled {
  if (_enabled == enabled) return;

  _enabled = enabled;
  [DefaultsManager setObject:@(_enabled) forKey:kDefaultsKeyFolderWatcher];

  if (_enabled) [self startWatchingFolders];
  else [self stopWatchingFolders];
}

- (void)startWatchingFolders {
  if ([LibraryFolder libraryFolders].count == 0) return;

  eventStream = FSEventStreamCreate(NULL,
                                    &handleEvent,
                                    NULL,
                                    (CFArrayRef)[LibraryFolder libraryFolders],
                                    [[DefaultsManager objectForKey:kDefaultsKeyLastFSEvent] longLongValue],
                                    eventLatency,
                                    kFSEventStreamCreateFlagNone);

  FSEventStreamScheduleWithRunLoop(eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStart(eventStream);
}

- (void)stopWatchingFolders {
  if (eventStream != nil) {
    FSEventStreamStop(eventStream);
    FSEventStreamInvalidate(eventStream);
    FSEventStreamRelease(eventStream);
    eventStream = nil;
  }
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
  NSMutableArray *folders = [NSMutableArray new];
  NSMutableArray *recursively = [NSMutableArray new];

  for (int i = 0; i < numEvents; i++) {
//    NSLog(@"Change %llu in %s, flags %d\n", eventIds[i], paths[i], eventFlags[i]&kFSEventStreamEventFlagMustScanSubDirs);
    [folders addObject:@(paths[i])];
    [recursively addObject:@(eventFlags[i]&kFSEventStreamEventFlagMustScanSubDirs)];
  }

  [[RescanProxy sharedProxy] rescanFolders:folders recursively:recursively];
  [folders release];
  [recursively release];

  [DefaultsManager setObject:@(eventIds[numEvents-1]) forKey:kDefaultsKeyLastFSEvent];
}

@end
