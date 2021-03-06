//
//  RescanProxy.m
//  Martin
//
//  Created by Tomislav Grbin on 12/24/12.
//
//

#import "RescanProxy.h"
#import "LibraryFoldersController.h"
#import "LibManager.h"
#import "RescanState.h"
#import "LibraryTree.h"
#import "FolderWatcher.h"
#import "NSObject+Observe.h"

// while events are coming in, don't rescan more than minQuietTime per second
// but don't wait for more than maxTimeWithoutRescan
// of course if no events are coming in, rescan wont be initiated after maxTime expires
static const double minQuietTime = 1;
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

    [self observe:kLibraryRescanFinishedNotification withAction:@selector(rescanFinished)];
  }
  return self;
}

- (void)rescanAll {
  @synchronized(rescanLock) {
    if (pathsToRescan.count >= 2) {
      id last = pathsToRescan.lastObject;
      id beforeLast = pathsToRescan[pathsToRescan.count - 2];
      if (last == specialRescanAllObject && beforeLast == specialRescanAllObject) return;
    }

    [pathsToRescan addObject:specialRescanAllObject];
    if (pathsToRescan.count == 1) [self initiateRescan];
  }
}

- (void)rescanRecursivelyTreeNodes:(NSArray *)treeNodes {
  @synchronized(rescanLock) {
    BOOL wasEmpty = pathsToRescan.count == 0;

    for (NSString *folderPath in [LibraryTree pathsForNodes:treeNodes]) {
      [pathsToRescan addObject:folderPath];
      [recursively addObject:@YES];
    }

    if (wasEmpty) [self initiateRescan];
  }
}

- (void)rescanFolders:(NSArray *)folderPaths recursively:(NSArray *)_recursively {
  @synchronized(rescanLock) {
    if (pathsToRescan.count == 0) {
      sinceLastRescanTimer = [self updateTimer:sinceLastRescanTimer
                                     withDelay:maxTimeWithoutRescan];
    }

    [pathsToRescan addObjectsFromArray:folderPaths];
    [recursively addObjectsFromArray:_recursively];

    quietTimeTimer = [self updateTimer:quietTimeTimer
                             withDelay:minQuietTime];
  }
}

- (void)rescanFinished {
  @synchronized(rescanLock) {
    [[FolderWatcher sharedWatcher] storeLastEventId];
    nowRescaning = NO;

    if (pathsToRescan.count) {
      if (quietTimeTimer == nil) {
        [self initiateRescan];
      } else {
        sinceLastRescanTimer = [self updateTimer:sinceLastRescanTimer
                                       withDelay:maxTimeWithoutRescan];
      }
    }
  }
}

- (void)initiateRescan {
  @synchronized(rescanLock) {
    quietTimeTimer = [self destroyTimer:quietTimeTimer];
    sinceLastRescanTimer = [self destroyTimer:sinceLastRescanTimer];
    
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

- (NSTimer *)updateTimer:(NSTimer *)timer withDelay:(double)delay {
  if (timer == nil) {
    return [NSTimer scheduledTimerWithTimeInterval:delay
                                               target:self
                                             selector:@selector(initiateRescan)
                                             userInfo:nil
                                              repeats:NO];
  } else {
    timer.fireDate = [NSDate dateWithTimeIntervalSinceNow:delay];
    return timer;
  }
}

- (NSTimer *)destroyTimer:(NSTimer *)timer {
  if (timer) {
    [timer invalidate];
  }
  return nil;
}

@end
