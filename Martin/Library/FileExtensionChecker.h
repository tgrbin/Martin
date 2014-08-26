//
//  FileExtensionChecker.h
//  Martin
//
//  Created by Tomislav Grbin on 2/3/13.
//
//

#import <Foundation/Foundation.h>

@interface FileExtensionChecker : NSObject

+ (NSArray *)acceptableExtensions;

+ (BOOL)isExtensionAcceptableForCStringFilename:(const char *)filename;
+ (BOOL)isExtensionAcceptableForFilename:(NSString *)filename;

@end
