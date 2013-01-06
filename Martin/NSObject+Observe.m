//
//  NSObject+Observe.m
//  Martin
//
//  Created by Tomislav Grbin on 1/6/13.
//
//

#import "NSObject+Observe.h"

@implementation NSObject (Observe)

- (void)observe:(NSString *)name withAction:(SEL)action {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:action
                                               name:name
                                             object:nil];
}

@end
