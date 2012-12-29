//
//  PlaylistPersistence.h
//  Martin
//
//  Created by Tomislav Grbin on 12/29/12.
//
//

#import <Foundation/Foundation.h>

@interface PlaylistPersistence : NSObject

+ (void)savePlaylists:(NSArray *)playlists;
+ (NSMutableArray *)loadPlaylists;

@end
