//
//  Song.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Song : NSObject

@property (nonatomic, assign) int inode;
@property (nonatomic, assign) int lengthInSeconds;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, assign) int lastModified;

@property (nonatomic, strong) NSDictionary *tagsDictionary;

@end
