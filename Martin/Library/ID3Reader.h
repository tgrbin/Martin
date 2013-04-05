//
//  ID3Reader.h
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>

@interface ID3Reader : NSObject {
  NSDictionary *id3;
  int lengthInSeconds;
}

- (id)initWithFile:(NSString *)_file;

- (NSString *)tag:(NSString *)tag;
- (int)lengthInSeconds;

@end
