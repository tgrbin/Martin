//
//  PlaylistNameGuesser.h
//  Martin
//
//  Created by Tomislav Grbin on 3/10/13.
//
//

#import <Foundation/Foundation.h>

@class Playlist;

@interface PlaylistNameGuesser : NSObject

+ (void)guessNameAndAddItems:(NSArray *)items toPlaylist:(Playlist *)playlist;
+ (void)itemsAndNameFromFolders:(NSArray *)folders withBlock:(void (^)(NSArray *items, NSString *name))block;

@end
