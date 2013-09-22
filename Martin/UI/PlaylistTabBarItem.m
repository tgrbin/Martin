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

- (id)init {
  if (self = [super init]) {
    _isProcessing = NO;
		_objectCount = 0;
		_isEdited = NO;
    _hasCloseButton = YES;
    _objectCountColor = nil;
    _icon = nil;
		_iconName = nil;
    _largeImage = nil;
  }
  return self;
}

- (NSString *)title {
  return _playlist.name;
}

- (void)setTitle:(NSString *)title {
  _playlist.name = title;
}

@end
