//
//  FileExtensionChecker.h
//  Martin
//
//  Created by Tomislav Grbin on 2/3/13.
//
//

#import <Foundation/Foundation.h>

@interface FileExtensionChecker : NSObject

+ (BOOL)isExtensionAcceptable:(const char *)filename;

@end
