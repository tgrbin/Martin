//
//  ID3Reader.m
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import "ID3Reader.h"

@implementation ID3Reader

- (id)initWithFile:(NSString *)_file {
  if (self = [super init]) {
    AudioFileID fileID = nil;
    const char *filename = [_file UTF8String];
    CFURLRef url = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (UInt8*)filename, strlen(filename), false);

    if (AudioFileOpenURL(url, kAudioFileReadPermission, 0, &fileID) == noErr) {
      CFDictionaryRef dict = nil;
      UInt32 size = sizeof(dict);
      if (AudioFileGetProperty(fileID, kAudioFilePropertyInfoDictionary, &size, &dict) == noErr) {
        id3 = (NSDictionary *)CFBridgingRelease(dict);
        lengthInSeconds = (int) [id3[@(kAFInfoDictionary_ApproximateDurationInSeconds)] doubleValue];
      }
    }

    CFRelease(url);
    AudioFileClose(fileID);

    if (id3 == nil) return nil;
  }
  return self;
}

- (NSString *)tag:(NSString *)tag {
  NSString *val = id3[tag];

  // year may have full timestamp format, we don't care about that
  if ([tag isEqualToString:@"year"]) {
    if (val.length < 4) return val;
    return [val substringToIndex:4];
  }

  return val;
}

- (int)lengthInSeconds {
  return lengthInSeconds;
}

@end
