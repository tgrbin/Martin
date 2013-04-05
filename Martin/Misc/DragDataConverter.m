//
//  DragDataConverter.m
//  Martin
//
//  Created by Tomislav Grbin on 1/6/13.
//
//

#import "DragDataConverter.h"

@implementation DragDataConverter

+ (NSData *)dataFromArray:(NSArray *)arr {
  return [NSKeyedArchiver archivedDataWithRootObject:arr];
}

+ (NSArray *)arrayFromData:(NSData *)data {
  return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

@end
