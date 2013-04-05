//
//  FileExtensionChecker.m
//  Martin
//
//  Created by Tomislav Grbin on 2/3/13.
//
//

#import "FileExtensionChecker.h"

@implementation FileExtensionChecker

+ (BOOL)isExtensionAcceptable:(const char *)str {
  int len = (int)strlen(str);
  if (strcasecmp(str + len - 4, ".mp3") == 0) return YES;
  if (strcasecmp(str + len - 4, ".m4a") == 0) return YES;
  return NO;
}

@end
