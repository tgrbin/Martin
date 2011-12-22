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

- (void) setTrackNumber:(NSString *)tn { // osigurava da se unutra namjesti broj
    [trackNumber release];
    
    if( [tn intValue] == 0 ) tn = @"";
    else trackNumber = [tn retain];
}

- (void)dealloc {
    [fullPath release];
    [artist release];
    [album release];
    [title release];
    [trackNumber release];
    [super dealloc];
}

@end
