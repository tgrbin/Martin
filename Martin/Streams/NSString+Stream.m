//
//  NSString+isURL.m
//  Martin
//
//  Created by Tomislav Grbin on 15/08/14.
//
//

#import "NSString+Stream.h"

@implementation NSString (Stream)

- (BOOL)isURL {
  NSString *lowercased = [self lowercaseString];
  return [lowercased hasPrefix:@"http://"] || [lowercased hasPrefix:@"https://"];
}

- (NSString *)URLify {
  if ([self isURL] == NO) {
    return [@"http://" stringByAppendingString:self];
  }
  
  return self;
}

@end
