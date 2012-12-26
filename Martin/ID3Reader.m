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
        lengthInSeconds = (int) [[id3 objectForKey:@"approximate duration in seconds"] doubleValue];
      }
    }

    CFRelease(url);
    AudioFileClose(fileID);

    if (id3 == nil) return nil;
  }
  return self;
}

- (NSString *)tag:(NSString *)tag {
  return [id3 objectForKey:tag];
}

- (int)lengthInSeconds {
  return lengthInSeconds;
}

@end
