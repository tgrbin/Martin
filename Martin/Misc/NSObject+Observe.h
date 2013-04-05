//
//  NSObject+Observe.h
//  Martin
//
//  Created by Tomislav Grbin on 1/6/13.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (Observe)

- (void)observe:(NSString *)name withAction:(SEL)action;

@end
