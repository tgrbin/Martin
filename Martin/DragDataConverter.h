//
//  DragDataConverter.h
//  Martin
//
//  Created by Tomislav Grbin on 1/6/13.
//
//

#import <Foundation/Foundation.h>

@interface DragDataConverter : NSObject

+ (NSData *)dataFromArray:(NSArray *)arr;
+ (NSArray *)arrayFromData:(NSData *)data;

@end
