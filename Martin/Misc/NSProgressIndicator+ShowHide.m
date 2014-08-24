//
//  NSProgressIndicator+ShowHide.m
//  Martin
//
//  Created by Tomislav Grbin on 24/08/14.
//
//

#import "NSProgressIndicator+ShowHide.h"

@implementation NSProgressIndicator (ShowHide)

- (void)show {
  self.hidden = NO;
  [self startAnimation:nil];
}

- (void)hide {
  self.hidden = YES;
  [self stopAnimation:nil];
}

@end
