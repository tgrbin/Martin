//
//  NSString+isURL.m
//  Martin
//
//  Created by Tomislav Grbin on 15/08/14.
//
//

#import "NSString+isURL.h"

@implementation NSString (isURL)

- (BOOL)isURL {
  NSString *lowercased = [self lowercaseString];
  return [lowercased hasPrefix:@"http://"] || [lowercased hasPrefix:@"https://"];
}

@end
