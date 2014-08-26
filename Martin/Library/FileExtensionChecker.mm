//
//  FileExtensionChecker.m
//  Martin
//
//  Created by Tomislav Grbin on 2/3/13.
//
//

#import "FileExtensionChecker.h"

#include <SFBAudioEngine/AudioPlayer.h>

@implementation FileExtensionChecker

static NSArray *extensionsArray;
static NSSet *extensionsSet;

+ (BOOL)isExtensionAcceptableForFilename:(NSString *)filename {
  return [self isExtensionAcceptable:[filename pathExtension]];
}

+ (BOOL)isExtensionAcceptableForCStringFilename:(const char *)filename {
  size_t len = strlen(filename);
  size_t extensionOffset;
  
  for (extensionOffset = len - 1; extensionOffset > 0; --extensionOffset) {
    if (filename[extensionOffset] == '.') break;
  }
  
  if (extensionOffset > 0) {
    NSString *extensionString = [NSString stringWithUTF8String:filename + extensionOffset + 1];
    return [self isExtensionAcceptable:extensionString];
  } else {
    return NO;
  }
}


+ (BOOL)isCStringExtensionAcceptable:(const char *)extension {
  NSString *extensionString = [[NSString stringWithUTF8String:extension] lowercaseString];
  return [self isExtensionAcceptable:extensionString];
}

+ (BOOL)isExtensionAcceptable:(NSString *)extension {
  if (extensionsSet == nil) {
    extensionsSet = [NSSet setWithArray:[self acceptableExtensions]];
  }
  
  return [extensionsSet member:[extension lowercaseString]] != nil;
}

+ (NSArray *)acceptableExtensions {
  if (extensionsArray == nil) {
    extensionsArray = (__bridge_transfer NSArray *)SFB::Audio::Decoder::CreateSupportedFileExtensions();
  }
  
  return extensionsArray;
}

@end
