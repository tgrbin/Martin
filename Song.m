//
//  Song.m
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Song.h"

@implementation Song

- (void)setTrackNumber:(NSString *)tn {
  if (tn.intValue == 0) tn = @"";
  _trackNumber = tn;
}

@end
