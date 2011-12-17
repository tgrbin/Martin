//
//  LastFM.m
//  Martin
//
//  Created by Tomislav Grbin on 12/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "LastFM.h"

@implementation LastFM

static NSString *sessionKey = @"0d50de13141911e11d521136bbe175f9";
static NSString *apiKey = @"3a570389ed801f07f07a7ea3d29d6673";
static NSString *apiSecret = @"6a6d7126bbaedb1413768474fb1c80bd";

+ (NSString*)md5HexDigest:(NSString*)input {
    const char* str = [input UTF8String];
    unsigned char result[16];
    CC_MD5(str, (unsigned int) strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:32];
    for(int i = 0; i < 16; i++) [ret appendFormat:@"%02x",result[i]];
    return ret;
}

+ (NSString*) apiSignatureForParams:(NSDictionary *)params {
    NSArray *keys = [params keysSortedByValueUsingComparator:^NSComparisonResult( NSString *a, NSString *b ) {
            return [a compare:b];
        }];
    
    NSString *str = @"";
    for( NSString *key in keys ) {
        str = [str stringByAppendingString:key];
        str = [str stringByAppendingString:[params valueForKey:key]];
    }
    str = [str stringByAppendingString:apiSecret];

    return [self md5HexDigest:str];
}

@end
