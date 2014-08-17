//
//  Stream.h
//  Martin
//
//  Created by Tomislav Grbin on 17/08/14.
//
//

#import <Foundation/Foundation.h>

typedef enum {
  kStreamNameRequestOutcomeConnectionFailed,
  kStreamNameRequestOutcomeNoName,
  kStreamNameRequestOutcomeSuccessfulyUpdatedName
} StreamNameRequestOutcome;

@class PlaylistItem;
@class Tags;

@interface Stream : NSObject

+ (Tags *)createTagsFromStream:(Stream *)stream;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, readonly) NSString *urlString;

- (instancetype)initWithURLString:(NSString *)urlString;

- (PlaylistItem *)createPlaylistItem;

- (void)sendRequestForStreamNameWithCompletionBlock:(void (^)(StreamNameRequestOutcome outcome))block;

@end
