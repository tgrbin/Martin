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
    
    const char *filename = [_file cStringUsingEncoding:NSUTF8StringEncoding];
    CFURLRef url = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (UInt8*)filename, strlen(filename), false);
    
    if (AudioFileOpenURL(url, kAudioFileReadPermission, 0, &fileID) != noErr) return nil;
    
    CFDictionaryRef dict = nil;
    UInt32 size = sizeof(dict);
    if (AudioFileGetProperty(fileID, kAudioFilePropertyInfoDictionary, &size, &dict) != noErr) return nil;
    
    id3 = (NSDictionary *)CFBridgingRelease(dict);
    if (id3 == nil) return nil;
  }
  return self;
}

- (NSString *)getTag:(NSString *)tag {
  return [id3 objectForKey:tag];
}

@end
