//
//  LastFM.h
//  Martin
//
//  Created by Tomislav Grbin on 12/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Song;

@interface LastFM : NSObject

+ (void) updateNowPlaying:(Song*)song delegate:(id)delegate;

@end
