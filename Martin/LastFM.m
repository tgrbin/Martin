//
//  LastFM.m
//  Martin
//
//  Created by Tomislav Grbin on 12/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "LastFM.h"
#import "PlaylistItem.h"
#import "Tags.h"

@implementation LastFM

static NSString * const apiURL = @"http://ws.audioscrobbler.com/2.0/";
static NSString * const apiKey = @"3a570389ed801f07f07a7ea3d29d6673";
static NSString * const apiSecret = @"6a6d7126bbaedb1413768474fb1c80bd";
static NSString * const sessionKeyKey = @"lastfmSessionKey";

static NSString *currentToken = nil;

+ (void)getAuthURLWithBlock:(void (^)(NSString *))callbackBlock {
  currentToken = nil;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *url = [apiURL stringByAppendingFormat:@"?method=auth.getToken&api_key=%@", apiKey];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSError *err;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:nil
                                                     error:&err];

    NSString *result = nil;
    if (data != nil) {
      NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      int l = (int)[str rangeOfString:@"<token>"].location;
      int r = (int)[str rangeOfString:@"</token>"].location;

      if (l != NSNotFound && r != NSNotFound) {
        currentToken = [str substringWithRange:NSMakeRange(l+7, r-l-7)];
        result = [NSString stringWithFormat:@"http://www.last.fm/api/auth/?api_key=%@&token=%@", apiKey, currentToken];
      }
    }

    dispatch_sync(dispatch_get_main_queue(), ^{ callbackBlock(result); });
  });
}

+ (void)getSessionKey:(void (^)(BOOL))callbackBlock {
  if (currentToken == nil) {
    callbackBlock(NO);
    return;
  }

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *sig = [self md5HexDigest:[NSString stringWithFormat:@"api_key%@methodauth.getSessiontoken%@%@", apiKey, currentToken, apiSecret]];
    NSString *url = [apiURL stringByAppendingFormat:@"?api_key=%@&method=auth.getSession&token=%@&api_sig=%@", apiKey, currentToken, sig];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSError *err;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:nil
                                                     error:&err];
    BOOL success = NO;
    if (data != nil) {
      NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      int l = (int)[str rangeOfString:@"<key>"].location;
      int r = (int)[str rangeOfString:@"</key>"].location;

      if (l != NSNotFound && r != NSNotFound) {
        NSString *sessionKey = [str substringWithRange:NSMakeRange(l+5, r-l-5)];
        [[NSUserDefaults standardUserDefaults] setObject:sessionKey forKey:sessionKeyKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        success = YES;
      }
    }

    dispatch_sync(dispatch_get_main_queue(), ^{ callbackBlock(success); });
  });
}

+ (void)resetSessionKey {
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:sessionKeyKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

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
  CFRelease(ref);
  CFRelease(dict);
}

+ (void)updateNowPlaying:(PlaylistItem *)item {
  NSString *sessionKey = [self sessionKey];
  if (sessionKey == nil) return;

  NSURL *u = [NSURL URLWithString:apiURL];
  NSString *name = @"track.updateNowPlaying";
  WSMethodInvocationRef myRef = WSMethodInvocationCreate((__bridge CFURLRef)u, (__bridge CFStringRef)name, kWSXMLRPCProtocol);

  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setValue:name forKey:@"method"];
  [params setValue:apiKey forKey:@"api_key"];
  [params setValue:sessionKey forKey:@"sk"];
  [self addItemTags:item toDictionary:params];

  [params setValue:[self apiSignatureForParams:params] forKey:@"api_sig"];

  NSDictionary *dict = [NSDictionary dictionaryWithObject:params forKey:@"params"];
  WSMethodInvocationSetParameters(myRef, (__bridge CFDictionaryRef)dict, (__bridge CFArrayRef)[dict allKeys]);

  WSMethodInvocationSetCallBack(myRef, &updateNowPlayingCallback, NULL);
  WSMethodInvocationScheduleWithRunLoop(myRef, [[NSRunLoop currentRunLoop] getCFRunLoop], (CFStringRef)NSDefaultRunLoopMode);
}

#pragma mark - scrobble

static void scrobbleCallback(WSMethodInvocationRef ref, void *info, CFDictionaryRef dict) {
  NSLog(@"scrobble callback :%@", dict);
  CFRelease(ref);
  CFRelease(dict);
}

+ (void)scrobble:(PlaylistItem *)item {
  NSString *sessionKey = [self sessionKey];
  if (sessionKey == nil) return;

  NSURL *u = [NSURL URLWithString:apiURL];
  NSString *name = @"track.scrobble";
  WSMethodInvocationRef myRef = WSMethodInvocationCreate((__bridge CFURLRef)u, (__bridge CFStringRef)name, kWSXMLRPCProtocol);

  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setValue:name forKey:@"method"];
  int timestamp = (int) [[NSDate date] timeIntervalSince1970];
  [params setValue:[NSString stringWithFormat:@"%d",timestamp] forKey:@"timestamp"];
  [self addItemTags:item toDictionary:params];

  [params setValue:apiKey forKey:@"api_key"];
  [params setValue:sessionKey forKey:@"sk"];
  [params setValue:[self apiSignatureForParams:params] forKey:@"api_sig"];

  NSDictionary *dict = [NSDictionary dictionaryWithObject:params forKey:@"params"];
  WSMethodInvocationSetParameters(myRef, (__bridge CFDictionaryRef)dict, (__bridge CFArrayRef)[dict allKeys]);

  WSMethodInvocationSetCallBack(myRef, &scrobbleCallback, NULL);
  WSMethodInvocationScheduleWithRunLoop(myRef, [[NSRunLoop currentRunLoop] getCFRunLoop], (CFStringRef)NSDefaultRunLoopMode);
}

+ (void)addItemTags:(PlaylistItem *)item toDictionary:(NSMutableDictionary *)dict {
  for (int i = 0; i < kNumberOfTags; ++i) {
    NSString *val = [item tagValueForIndex:i];
    NSString *lastfmTag = [Tags tagNameForIndex:i];
    if ([lastfmTag isEqualToString:@"track"]) lastfmTag = @"trackNumber";
    if ([lastfmTag isEqualToString:@"title"]) lastfmTag = @"track";
    [dict setValue:val forKey:lastfmTag];
  }
}

+ (NSString *)sessionKey {
  return [[NSUserDefaults standardUserDefaults] objectForKey:sessionKeyKey];
}

@end
