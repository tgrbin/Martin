//
//  PlaylistNameGuesser.h
//  Martin
//
//  Created by Tomislav Grbin on 3/10/13.
//
//

#import <Foundation/Foundation.h>

@class Playlist;

@interface ItemsAndName : NSObject
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSString *name;
@end

@interface PlaylistNameGuesser : NSObject

+ (void)guessNameAndAddItems:(NSArray *)items toPlaylist:(Playlist *)playlist;
+ (ItemsAndName *)itemsAndNameFromFolders:(NSArray *)folders;

@end
