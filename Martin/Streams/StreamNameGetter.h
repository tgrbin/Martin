//
//  StreamNameGetter.h
//  Martin
//
//  Created by Tomislav Grbin on 16/08/14.
//
//

#import <Foundation/Foundation.h>

@interface StreamNameGetter : NSObject

- (instancetype)initWithURLString:(NSString *)urlString andBlock:(void (^)(NSString *streamName))block;

- (void)start;

@end
