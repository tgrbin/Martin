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
#import "RescanState.h"
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

// this object is added to the queue when rescan all is requested
static id specialRescanAllObject;

+ (RescanProxy *)sharedProxy {
  static RescanProxy *o;
  if (o == nil) {
    o = [RescanProxy new];
    specialRescanAllObject = @0;
  }
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
  @synchronized(rescanLock) {
    if (pathsToRescan.lastObject != specialRescanAllObject) {
      [pathsToRescan addObject:specialRescanAllObject];
      if (pathsToRescan.count == 1) [self initiateRescan];
    }
  }
}

- (void)rescanRecursivelyTreeNodes:(NSArray *)treeNodes {
  @synchronized(rescanLock) {
    BOOL wasEmpty = pathsToRescan.count == 0;

    for (NSString *folderPath in [Tree pathsForNodes:treeNodes]) {
      [pathsToRescan addObject:folderPath];
      [recursively addObject:@YES];
    }

    if (wasEmpty) [self initiateRescan];
  }
}

- (void)rescanFolders:(NSArray *)folderPaths recursively:(NSArray *)_recursively {
  @synchronized(rescanLock) {
    if (pathsToRescan.count == 0) [self setTimer:&sinceLastRescanTimer withDelay:maxTimeWithoutRescan];

    [pathsToRescan addObjectsFromArray:folderPaths];
    [recursively addObjectsFromArray:_recursively];

    [self setTimer:&quietTimeTimer withDelay:minQuietTime];
  }
}

- (void)rescanFinished {
  @synchronized(rescanLock) {
    nowRescaning = NO;

    if (pathsToRescan.count) {
      if (quietTimeTimer == nil) [self initiateRescan];
      else [self setTimer:&sinceLastRescanTimer withDelay:maxTimeWithoutRescan];
    }
  }
}

- (void)initiateRescan {
  @synchronized(rescanLock) {
    [self destroyTimer:&quietTimeTimer];
    [self destroyTimer:&sinceLastRescanTimer];

    if (nowRescaning == NO && pathsToRescan.count > 0) {
      nowRescaning = YES;
      if (pathsToRescan[0] == specialRescanAllObject) {
        [LibManager rescanAll];
        [pathsToRescan removeObjectAtIndex:0];
      } else {
        NSUInteger rescanAllIndex = [pathsToRescan indexOfObject:specialRescanAllObject];
        if (rescanAllIndex == NSNotFound) rescanAllIndex = pathsToRescan.count;

        NSRange range = NSMakeRange(0, rescanAllIndex);
        [LibManager rescanPaths:[pathsToRescan subarrayWithRange:range]
                    recursively:[recursively subarrayWithRange:range]];

        [pathsToRescan removeObjectsInRange:range];
        [recursively removeObjectsInRange:range];
      }
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
