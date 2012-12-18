//
//  FSEventsProcessor.h
//  Martin
//
//  Created by Tomislav Grbin on 12/18/12.
//
//

#import <Foundation/Foundation.h>

@interface FSEventsProcessor : NSObject {
  NSMutableArray *pathQueue;
  NSTimer *lastRescanTimer;
  NSTimer *lastEventTimer;

  NSLock *lock;
}

+ (FSEventsProcessor *)sharedProcessor;

- (void)pathChanged:(const char *)path;

@end
