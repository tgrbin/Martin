//
//  SleepPreventer.h
//  Martin
//
//  Created by Tomislav Grbin on 12/16/12.
//
//

#import <Foundation/Foundation.h>

@interface SleepPreventer : NSObject

+ (void)setAllowsSleep:(BOOL)allowed;
+ (BOOL)allowsSleep;

@end
