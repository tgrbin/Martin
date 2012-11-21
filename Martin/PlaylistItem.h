//
//  PlaylistItem.h
//  Martin
//
//  Created by Tomislav Grbin on 11/20/12.
//
//

#import <Foundation/Foundation.h>

@class Song;

@interface PlaylistItem : NSObject

- (id)initWithInode:(int)inode;
- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionary;

@property (nonatomic, assign) int inode;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, assign) int lengthInSeconds;
@property (nonatomic, strong) NSDictionary *tags;

@property (nonatomic, strong) Song *song;

@end
