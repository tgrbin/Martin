//
//  PlayerStatusTextField.m
//  Martin
//
//  Created by Tomislav Grbin on 9/14/13.
//
//

#import "PlayerStatusTextField.h"
#import "PlaylistItem.h"
#import "MartinAppDelegate.h"

#import "STKHTTPDataSource.h" // for getting meta data

#import "NSObject+Observe.h"

static NSString * const kStoppedText = @"--";

static NSString * const kPathSeparator = @" / ";
static NSString * const kTagSeparator = @" - ";

static const int kPlayingOpacity = 70;
static const int kStoppedOpacity = 40;

@interface PlayerStatusTextField()

@property (nonatomic, strong) NSDictionary *textAttributes;

@property (nonatomic, assign) BOOL mouseDragged;

@property (nonatomic, strong) NSString *metaDataTitle;
@end

@implementation PlayerStatusTextField

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    self.textAttributes = [NSDictionary dictionaryWithObject:self.font
                                                      forKey:NSFontAttributeName];
    
    [self observe:kGotNewMetaDataNotification
       withAction:@selector(gotNewMetaData:)];
  }
  return self;
}

- (void)setStatus:(PlayerStatus)status {
  _status = status;

  int opacity = (status == kPlayerStatusPlaying)? kPlayingOpacity: kStoppedOpacity;
  self.textColor = [NSColor colorWithCalibratedWhite:0 alpha:opacity / 100.];

  [self updateDisplayText];
}

- (void)setPlaylistItem:(PlaylistItem *)playlistItem {
  _playlistItem = playlistItem;
  self.metaDataTitle = nil;
  [self updateDisplayText];
}

- (void)gotNewMetaData:(NSNotification *)notification {
  self.metaDataTitle = notification.userInfo[@"streamTitle"];
  [self updateDisplayText];
}

- (void)updateDisplayText {
  NSString *text = kStoppedText;

  if (_status != kPlayerStatusStopped && _playlistItem != nil) {
    if (_playlistItem.isURLStream) {
      if (self.metaDataTitle != nil) {
        text = self.metaDataTitle;
      } else {
        text = [_playlistItem tagValueForIndex:kTagIndexTitle];
      }
    } else {
      NSString *title = [_playlistItem tagValueForIndex:kTagIndexTitle];

      if (title.length == 0) {
        NSArray *pathComponents = [[_playlistItem.filename stringByDeletingPathExtension] pathComponents];
        text = [pathComponents lastObject];
        for (NSInteger i = pathComponents.count - 2; i >= 0; --i) {
          NSString *longerText = [NSString stringWithFormat:@"%@%@%@", pathComponents[i], kPathSeparator, text];

          if ([self canFitString:longerText]) {
            text = longerText;
          } else {
            break;
          }
        }
      } else {
        NSString *album = [_playlistItem tagValueForIndex:kTagIndexAlbum];
        NSString *artist = [_playlistItem tagValueForIndex:kTagIndexArtist];

        text = [self fitTagsOrNil:@[ artist, album, title ]];
        if (text == nil) text = [self fitTagsOrNil:@[ artist, title ]];
        if (text == nil) text = title;
      }
    }
  }

  self.stringValue = text;
}

- (NSString *)fitTagsOrNil:(NSArray *)tags {
  NSString *str = [tags componentsJoinedByString:kTagSeparator];
  return [self canFitString:str]? str: nil;
}

- (BOOL)canFitString:(NSString *)str {
  NSSize size = [str sizeWithAttributes:_textAttributes];
  return size.width < self.frame.size.width;
}

- (void)setFrame:(NSRect)frameRect {
  [super setFrame:frameRect];
  [self updateDisplayText];
}

- (void)mouseDragged:(NSEvent *)theEvent {
  _mouseDragged = YES;
}

- (void)mouseUp:(NSEvent *)theEvent {
  if (_mouseDragged == NO) {
    [[MartinAppDelegate get].tabsManager selectNowPlayingPlaylist];
  }
  _mouseDragged = NO;
}

@end
