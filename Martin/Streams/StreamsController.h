//
//  StreamsController.h
//  Martin
//
//  Created by Tomislav Grbin on 17/08/14.
//
//

#import <Foundation/Foundation.h>

extern NSString * const kStreamsUpdatedNotification;

@class Stream;

@interface StreamsController : NSObject

@property (nonatomic, readonly) NSArray *streams;

@property (nonatomic, assign) BOOL showStreamsInLibraryPane;

// returns nil if stream doesn't exist
- (Stream *)streamWithURLString:(NSString *)urlString;

// create stream with url, don't send request for title
- (Stream *)createStreamWithURLString:(NSString *)urlString;

// if stream doesn't exist, this method will create it and send request to
// fetch stream's title
- (Stream *)createOrReturnStreamWithURLString:(NSString *)urlString;

- (void)removeStream:(Stream *)stream;
- (void)reorderStreamAtIndex:(NSInteger)index toNewIndex:(NSInteger)newIndex;

- (void)storeStreams;

@end
