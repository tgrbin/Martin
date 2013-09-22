//
//  PlaylistTabBarItem.h
//  Martin
//
//  Created by Tomislav Grbin on 9/22/13.
//
//

#import <Foundation/Foundation.h>
#import "MMTabBarItem.h"

@class Playlist;

@interface PlaylistTabBarItem : NSObject <MMTabBarItem>

@property (nonatomic, strong) Playlist *playlist;

@property (copy)   NSString *title;
@property (retain) NSImage  *largeImage;
@property (retain) NSImage  *icon;
@property (retain) NSString *iconName;

@property (assign) BOOL      isProcessing;
@property (assign) NSInteger objectCount;
@property (retain) NSColor   *objectCountColor;
@property (assign) BOOL      isEdited;
@property (assign) BOOL      hasCloseButton;

@end
