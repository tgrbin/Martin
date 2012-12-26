//
//  RescanProxy.m
//  Martin
//
//  Created by Tomislav Grbin on 12/24/12.
//
//

#import "RescanProxy.h"
#import "LibraryFolder.h"
#import "LibManager.h"
#import "Tree.h"

static const double minQuietTime = 0.5;
static const double maxTimeWithoutRescan = 3;

@implementation RescanProxy {
  NSLock *rescanLock;

  BOOL nowRescaning;
  NSMutableArray *pathsToRescan;
  NSMutableArray *recursively;

  NSTimer *quietTimeTimer;
  NSTimer *sinceLastRescanTimer;
}

+ (RescanProxy *)sharedProxy {
  static RescanProxy *o;
  if (o == nil) o = [RescanProxy new];
  return o;
}

- (id)init {
  if (self = [super init]) {
    rescanLock = [NSLock new];
    pathsToRescan = [NSMutableArray new];
    recursively = [NSMutableArray new];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rescanFinished)
                                                 name:kLibraryRescanFinishedNotification
                                               object:nil];
  }
  return self;
}

- (void)rescanAll {
  [LibManager rescanAll];
}

- (void)rescanRecursivelyTreeNodes:(NSArray *)treeNodes {
  BOOL wasEmpty;

  @synchronized(rescanLock) {
    wasEmpty = pathsToRescan.count == 0;

    for (NSString *folderPath in [Tree pathsForNodes:treeNodes]) {
      [pathsToRescan addObject:folderPath];
      [recursively addObject:@YES];
    }
  }

  if (wasEmpty) [self initiateRescan];
}

- (void)rescanFolder:(NSString *)folderPath recursively:(BOOL)_recursively {
  @synchronized(rescanLock) {
    [pathsToRescan addObject:folderPath];
    [recursively addObject:@(_recursively)];

    [self setTimer:&quietTimeTimer withDelay:minQuietTime];
  }
}

- (void)rescanFinished {
  @synchronized(rescanLock) {
    nowRescaning = NO;

    if (pathsToRescan.count) {
      [self setTimer:&sinceLastRescanTimer withDelay:maxTimeWithoutRescan];
    }
  }
}

- (void)initiateRescan {
  @synchronized(rescanLock) {
    [self destroyTimer:&quietTimeTimer];
    [self destroyTimer:&sinceLastRescanTimer];

    if (nowRescaning == NO && pathsToRescan.count > 0) {
      nowRescaning = YES;
      [LibManager rescanPaths:pathsToRescan recursively:recursively];
      [pathsToRescan removeAllObjects];
      [recursively removeAllObjects];
    }
  }
}

- (void)setTimer:(NSTimer **)timer withDelay:(double)delay {
  if (*timer == nil) {
    *timer = [[NSTimer scheduledTimerWithTimeInterval:delay
                                               target:self
                                             selector:@selector(initiateRescan)
                                             userInfo:nil
                                              repeats:NO] retain];
  } else {
    (*timer).fireDate = [NSDate dateWithTimeIntervalSinceNow:delay];
  }
}

- (void)destroyTimer:(NSTimer **)timer {
  if (*timer) {
    [*timer invalidate];
    [*timer release];
    *timer = nil;
  }
}

@end
