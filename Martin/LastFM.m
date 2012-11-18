//
//  LastFM.m
//  Martin
//
//  Created by Tomislav Grbin on 12/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "LastFM.h"
#import "Song.h"

@implementation LastFM

static NSString *url = @"http://ws.audioscrobbler.com/2.0/";
static NSString *sessionKey = @"0d50de13141911e11d521136bbe175f9";
static NSString *apiKey = @"3a570389ed801f07f07a7ea3d29d6673";
static NSString *apiSecret = @"6a6d7126bbaedb1413768474fb1c80bd";

+ (NSString *)md5HexDigest:(NSString *)input {
  const char *str = [input UTF8String];
  unsigned char result[16];
  CC_MD5(str, (unsigned int) strlen(str), result);
  
  NSMutableString *ret = [NSMutableString stringWithCapacity:32];
  for (int i = 0; i < 16; i++) [ret appendFormat:@"%02x", result[i]];
  return ret;
}

+ (NSString *)apiSignatureForParams:(NSDictionary *)params {
  NSArray *keys = [[params allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
    return [a compare:b];
  }];
      
  NSString *str = @"";
  for (NSString *key in keys) {
    str = [str stringByAppendingString:key];
    str = [str stringByAppendingString:[params valueForKey:key]];
  }
  str = [str stringByAppendingString:apiSecret];

  return [self md5HexDigest:str];
}

#pragma mark - update now playing

static void updateNowPlayingCallback(WSMethodInvocationRef ref, void *info, CFDictionaryRef dict) {
  NSLog(@"updateNowPlaying callback: %@", dict);
}

+ (void)updateNowPlaying:(Song *)song {
  NSURL *u = [NSURL URLWithString:url];
  NSString *name = @"track.updateNowPlaying";
  WSMethodInvocationRef myRef = WSMethodInvocationCreate((__bridge CFURLRef)u, (__bridge CFStringRef)name, kWSXMLRPCProtocol);
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setValue:name forKey:@"method"];
  [params setValue:apiKey forKey:@"api_key"];
  [params setValue:sessionKey forKey:@"sk"];
  [self addSongTags:song toDictionary:params];
  
  [params setValue:[self apiSignatureForParams:params] forKey:@"api_sig"];
  
  NSDictionary *dict = [NSDictionary dictionaryWithObject:params forKey:@"params"];
  WSMethodInvocationSetParameters(myRef, (__bridge CFDictionaryRef)dict, (__bridge CFArrayRef)[dict allKeys]);
  
  WSMethodInvocationSetCallBack(myRef, &updateNowPlayingCallback, NULL);
  WSMethodInvocationScheduleWithRunLoop(myRef, [[NSRunLoop currentRunLoop] getCFRunLoop], (CFStringRef)NSDefaultRunLoopMode );
}

#pragma mark - scrobble

static void scrobbleCallback(WSMethodInvocationRef ref, void *info, CFDictionaryRef dict) {
  NSLog(@"scrobble callback :%@", dict);
}

+ (void)scrobble:(Song *)song {
  NSURL *u = [NSURL URLWithString:url];
  NSString *name = @"track.scrobble";
  WSMethodInvocationRef myRef = WSMethodInvocationCreate((__bridge CFURLRef)u, (__bridge CFStringRef)name, kWSXMLRPCProtocol);
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setValue:name forKey:@"method"];
  int timestamp = (int) [[NSDate date] timeIntervalSince1970];
  [params setValue:[NSString stringWithFormat:@"%d",timestamp] forKey:@"timestamp"];
  [self addSongTags:song toDictionary:params];

  [params setValue:apiKey forKey:@"api_key"];
  [params setValue:sessionKey forKey:@"sk"];
  [params setValue:[self apiSignatureForParams:params] forKey:@"api_sig"];
  
  NSDictionary *dict = [NSDictionary dictionaryWithObject:params forKey:@"params"];
  WSMethodInvocationSetParameters(myRef, (__bridge CFDictionaryRef)dict, (__bridge CFArrayRef)[dict allKeys]);
  
  WSMethodInvocationSetCallBack(myRef, &scrobbleCallback, NULL);
  WSMethodInvocationScheduleWithRunLoop(myRef, [[NSRunLoop currentRunLoop] getCFRunLoop], (CFStringRef)NSDefaultRunLoopMode);
}

+ (void)addSongTags:(Song *)song toDictionary:(NSMutableDictionary *)dict {
  for (NSString *tag in song.tagsDictionary) {
    NSString *val = [song.tagsDictionary objectForKey:tag];
    [dict setValue:val forKey:[tag isEqualToString:@"track number"]? @"track": tag];
  }
}

@end
