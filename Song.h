//
//  Song.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Song : NSObject

@property (assign) int ID;
@property (nonatomic, retain) NSString *fullPath;
@property (nonatomic, retain) NSString *trackNumber;
@property (nonatomic, retain) NSString *artist;
@property (nonatomic, retain) NSString *album;
@property (nonatomic, retain) NSString *title;

@end
