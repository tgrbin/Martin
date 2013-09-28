//
//  PlaylistTabBarItem.m
//  Martin
//
//  Created by Tomislav Grbin on 9/22/13.
//
//

#import "PlaylistTabBarItem.h"
#import "Playlist.h"

@implementation PlaylistTabBarItem

@synthesize title = _title;

- (id)initWithPlaylist:(Playlist *)playlist {
  if (self = [super init]) {
    _isProcessing = NO;
		_objectCount = 0;
		_isEdited = NO;
    _hasCloseButton = YES;
    _objectCountColor = nil;
    _icon = nil;
		_iconName = nil;
    _largeImage = nil;

    self.playlist = playlist;
    _title = playlist.name;
  }
  return self;
}

- (NSString *)title {
  return _title;
}

- (void)setTitle:(NSString *)title {
  _title = [title copy];
  _playlist.name = _title;
}

@end
