//
//  ID3ReadOperation.h
//  Martin
//
//  Created by Tomislav Grbin on 3/10/13.
//
//

#import <Foundation/Foundation.h>

@class PlaylistItem;

@interface ID3ReadOperation : NSOperation

- (id)initWithPlaylistItem:(PlaylistItem *)playlistItem;

@end
