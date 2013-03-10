//
//  PlaylistItem.h
//  Martin
//
//  Created by Tomislav Grbin on 11/20/12.
//
//

#import <Foundation/Foundation.h>
#import "Tags.h"

@interface PlaylistItem : NSObject

- (id)initWithLibrarySong:(int)p_song;
- (id)initWithFileStream:(FILE *)f;
- (id)initWithPath:(NSString *)path andInode:(ino_t)inode;

@property (nonatomic, strong, readonly) NSString *filename;
@property (nonatomic, readonly) ino_t inode;
@property (nonatomic, assign) int lengthInSeconds;
@property (nonatomic, readonly) int p_librarySong;

- (void)createTagsFromArray:(NSArray *)array;

- (NSString *)tagValueForIndex:(TagIndex)i;
- (NSString *)prettyName;

- (void)outputToFileStream:(FILE *)f;

- (void)cancelID3Read;

@end
