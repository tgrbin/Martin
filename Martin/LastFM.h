//
//  LastFM.h
//  Martin
//
//  Created by Tomislav Grbin on 12/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LastFM : NSObject

+ (NSString*) apiSignatureForParams:(NSDictionary*)params;

@end
