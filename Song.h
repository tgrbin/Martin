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
@property (nonatomic, strong) NSString *fullPath;
@property (nonatomic, strong) NSString *trackNumber;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *album;
@property (nonatomic, strong) NSString *title;

@end
