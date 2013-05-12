//
//  FileExtensionChecker.m
//  Martin
//
//  Created by Tomislav Grbin on 2/3/13.
//
//

#import "FileExtensionChecker.h"

@implementation FileExtensionChecker

static const int N = 7;
static const char extensions[][5] = { "mp3", "wav", "m4a", "aac", "caf", "ac3", "aiff" };
static const int lengths[] = { 3, 3, 3, 3, 3, 3, 4 };

+ (BOOL)isExtensionAcceptable:(const char *)str {
  int len = (int)strlen(str);

  for (int i = 0; i < N; ++i)
    if (strcasecmp(str + len - lengths[i], extensions[i]) == 0) return YES;

  return NO;
}

+ (NSArray *)acceptableExtensions {
  NSMutableArray *arr = [NSMutableArray new];
  for (int i = 0; i < N; ++i) [arr addObject:@(extensions[i])];
  return arr;
}

@end
