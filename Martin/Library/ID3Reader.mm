//
//  ID3Reader.m
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import "ID3Reader.h"

#include <SFBAudioEngine/AudioMetadata.h>

@implementation ID3Reader {
  NSMutableDictionary *id3;
  int lengthInSeconds;
}

- (id)initWithFile:(NSString *)file {
  if (self = [super init]) {
    NSURL *url = [NSURL fileURLWithPath:file isDirectory:NO];
    auto metadata = SFB::Audio::Metadata::CreateMetadataForURL((__bridge CFURLRef)url);
    
    if (metadata) {
      lengthInSeconds = [(__bridge NSNumber *)metadata->GetDuration() intValue];
      
      id3 = [NSMutableDictionary new];
      
      [self checkAndSet:@"artist" value:metadata->GetArtist()];
      [self checkAndSet:@"album" value:metadata->GetAlbumTitle()];
      [self checkAndSet:@"title" value:metadata->GetTitle()];
      [self checkAndSet:@"genre" value:metadata->GetGenre()];
      [self checkAndSet:@"year" value:metadata->GetReleaseDate()];
      
      CFNumberRef trackNumber = metadata->GetTrackNumber();
      NSInteger trackNumberInteger = [(__bridge NSNumber *)trackNumber intValue];
      if (trackNumberInteger > 0) {
        id3[@"track number"] = [@(trackNumberInteger) description];
      }
    } else {
      return nil;
    }
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

- (void)checkAndSet:(NSString *)key value:(CFStringRef)value {
  NSString *valueString = (__bridge NSString *)value;
  
  if (valueString != nil) {
    id3[key] = valueString;
  }
}

@end
