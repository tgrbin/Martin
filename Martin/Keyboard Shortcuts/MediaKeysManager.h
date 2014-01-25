//
//  MediaKeysManager.h
//  Martin
//
//  Created by Tomislav Grbin on 25/01/14.
//
//

#import <Foundation/Foundation.h>

@interface MediaKeysManager : NSObject

+ (MediaKeysManager *)shared;

@property (nonatomic, assign) BOOL mediaKeysEnabled;

@end
