//
//  LastFM.m
//  Martin
//
//  Created by Tomislav Grbin on 12/17/11.
//

#import <CommonCrypto/CommonDigest.h>
#import "LastFM.h"
#import "PlaylistItem.h"
#import "Tags.h"
#import "DefaultsManager.h"

@implementation LastFM

static NSString * const apiURL = @"http://ws.audioscrobbler.com/2.0/";
static NSString * const apiKey = @"3a570389ed801f07f07a7ea3d29d6673";
static NSString * const apiSecret = @"6a6d7126bbaedb1413768474fb1c80bd";

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
      NSInteger l = [str rangeOfString:@"<token>"].location;
      NSInteger r = [str rangeOfString:@"</token>"].location;

      if (l != NSNotFound && r != NSNotFound) {
        currentToken = [str substringWithRange:NSMakeRange(l+7, r-l-7)];
        result = [NSString stringWithFormat:@"http://www.last.fm/api/auth/?api_key=%@&token=%@", apiKey, currentToken];
      }
    }

    dispatch_async(dispatch_get_main_queue(), ^{ callbackBlock(result); });
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
      NSInteger l = [str rangeOfString:@"<key>"].location;
      NSInteger r = [str rangeOfString:@"</key>"].location;

      if (l != NSNotFound && r != NSNotFound) {
        NSString *sessionKey = [str substringWithRange:NSMakeRange(l+5, r-l-5)];
        [DefaultsManager setObject:sessionKey forKey:kDefaultsKeyLastFMSession];
        success = YES;
      }
    }

    dispatch_async(dispatch_get_main_queue(), ^{ callbackBlock(success); });
  });
}

+ (BOOL)isScrobbling {
  return [self sessionKey] != nil;
}

+ (void)stopScrobbling {
  [DefaultsManager setObject:nil forKey:kDefaultsKeyLastFMSession];
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

+ (void)updateNowPlaying:(PlaylistItem *)item {
#ifndef DEBUG
  if (item.isURLStream == YES || [self sessionKey] == nil) return;
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  params[@"method"] = @"track.updateNowPlaying";
  
  [self addCommonParamsForItem:item toParams:params];
  
  NSURLRequest *request = [self createURLRequestWithParams:params];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[NSOperationQueue mainQueue]
                         completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                           if (![response isKindOfClass:[NSHTTPURLResponse class]] ||
                               [((NSHTTPURLResponse *)response) statusCode] != 200) {
                             NSLog(@"update now playing failed: params: %@, response: %@, response data: %@",
                                   params,
                                   response,
                                   [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                           }
                         }];
#endif
}

+ (void)scrobble:(PlaylistItem *)item {
#ifndef DEBUG
  if (item.isURLStream == YES || [self sessionKey] == nil) return;

  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  params[@"method"] = @"track.scrobble";
  int timestamp = (int) [[NSDate date] timeIntervalSince1970];
  params[@"timestamp"] = [@(timestamp) stringValue];
  
  [self addCommonParamsForItem:item toParams:params];

  NSURLRequest *request = [self createURLRequestWithParams:params];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[NSOperationQueue mainQueue]
                         completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                           if (![response isKindOfClass:[NSHTTPURLResponse class]] ||
                               [((NSHTTPURLResponse *)response) statusCode] != 200) {
                             NSLog(@"scrobble failed: params: %@, response: %@, response data: %@",
                                   params,
                                   response,
                                   [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                           }
  }];
#endif
}

+ (void)addCommonParamsForItem:(PlaylistItem *)item toParams:(NSMutableDictionary *)params {
  params[@"api_key"] = apiKey;
  params[@"sk"] = [self sessionKey];
  [self addItemTags:item toDictionary:params];
  params[@"api_sig"] = [self apiSignatureForParams:params];
}

+ (NSURLRequest *)createURLRequestWithParams:(NSDictionary *)params {
  NSMutableString *payload = [NSMutableString new];
  for (id key in params) {
    if (payload.length > 0) [payload appendString:@"&"];
    [payload appendFormat:@"%@=%@", key, [params[key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  }
  NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
  
  NSURL *url = [NSURL URLWithString:apiURL];
  NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
  [urlRequest setHTTPMethod:@"POST"];
  [urlRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
  [urlRequest setValue:@"Martin OSX audio player" forHTTPHeaderField:@"User-Agent"];
  [urlRequest setHTTPBody:payloadData];
  [urlRequest setValue:[@([payloadData length]) stringValue] forHTTPHeaderField:@"Content-Length"];
  
  return urlRequest;
}

+ (void)addItemTags:(PlaylistItem *)item toDictionary:(NSMutableDictionary *)dict {
  for (int i = 0; i < kNumberOfTags; ++i) {
    NSString *val = [item tagValueForIndex:i];
    NSString *lastfmTag = [Tags tagNameForIndex:i];
    if ([lastfmTag isEqualToString:@"track number"]) lastfmTag = @"trackNumber";
    if ([lastfmTag isEqualToString:@"title"]) lastfmTag = @"track";
    [dict setValue:val forKey:lastfmTag];
  }
}

+ (NSString *)sessionKey {
  return [DefaultsManager objectForKey:kDefaultsKeyLastFMSession];
}

@end
