//
//  FSEventsProcessor.m
//  Martin
//
//  Created by Tomislav Grbin on 12/18/12.
//
//

#import "FSEventsProcessor.h"
#import "LibManager.h"

@implementation FSEventsProcessor

// if there is no fsevent for idleTimeBeforeRescanTime, new rescan is initiated with folders received
// if events are arriving all the time, new rescan will be initiated after timeBetweenRescans time
static const double idleTimeBeforeRescan = 1;
static const double timeBetweenRescans = 3;

+ (FSEventsProcessor *)sharedProcessor {
  static FSEventsProcessor *o;
  if (o == nil) o = [[FSEventsProcessor alloc] init];
  return o;
}

- (id)init {
  if (self = [super init]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(libraryRescanFinished)
                                                 name:kLibraryRescanFinishedNotification
                                               object:nil];

    pathQueue = [NSMutableArray new];
    lock = [NSLock new];
  }
  return self;
}

- (void)pathChanged:(const char *)path {
  @synchronized(lock) {
    [pathQueue addObject:[NSString stringWithCString:path encoding:NSUTF8StringEncoding]];

    if (lastEventTimer) {
      lastEventTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:idleTimeBeforeRescan];
    } else {
      lastEventTimer = [NSTimer scheduledTimerWithTimeInterval:idleTimeBeforeRescan
                                                        target:self
                                                      selector:@selector(timerFired)
                                                      userInfo:nil
                                                       repeats:NO];
      [self setupRescanTimer];
    }
  }
}

- (void)libraryRescanFinished {
  @synchronized(lock) {
    if (pathQueue.count) {
      [self setupRescanTimer];
    }
  }
}

- (void)setupRescanTimer {
  if (lastRescanTimer) {
    lastRescanTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:timeBetweenRescans];
  } else {
    lastRescanTimer = [NSTimer scheduledTimerWithTimeInterval:timeBetweenRescans
                                                       target:self
                                                     selector:@selector(timerFired)
                                                     userInfo:nil
                                                      repeats:NO];
  }
}

- (void)timerFired {
  @synchronized(lock) {
    [lastRescanTimer invalidate];
    lastRescanTimer = nil;
    [lastEventTimer invalidate];
    lastEventTimer = nil;

    if (pathQueue.count) {
      [LibManager rescanPaths:pathQueue];
      [pathQueue removeAllObjects];
    }
  }
}

@end
