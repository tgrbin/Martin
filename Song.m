//
//  Song.m
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Song.h"

@implementation Song

@synthesize fullPath, artist, album, title, trackNumber, ID;

- (void)dealloc {
    [fullPath release];
    [artist release];
    [album release];
    [title release];
    [trackNumber release];
    [super dealloc];
}

@end
