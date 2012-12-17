//
//  SleepPreventer.m
//  Martin
//
//  Created by Tomislav Grbin on 12/16/12.
//
//

#import <IOKit/pwr_mgt/IOPMLib.h>
#import "SleepPreventer.h"

@implementation SleepPreventer

static NSString * const kSleepAllowedKey = @"SleepAllowedKey";

static BOOL sleepAllowed;
static IOPMAssertionID assertionID;

+ (void)initialize {
  sleepAllowed = YES;
  [self setAllowsSleep:[self allowsSleep]];
}

+ (void)setAllowsSleep:(BOOL)isAllowed {
  if (isAllowed == sleepAllowed) return;

  if (sleepAllowed == NO) {
    NSString *message = @"Martin is still playing.";
    IOPMAssertionCreateWithName(kIOPMAssertionTypeNoIdleSleep,
                                kIOPMAssertionLevelOn,
                                (__bridge CFStringRef) message,
                                &assertionID);
  } else {
    IOPMAssertionRelease(assertionID);
  }

  sleepAllowed = isAllowed;

  if (sleepAllowed) [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSleepAllowedKey];
  else [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kSleepAllowedKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)allowsSleep {
  return [[NSUserDefaults standardUserDefaults] objectForKey:kSleepAllowedKey] == nil;
}

@end
