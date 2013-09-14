//
//  PlayerStatusTextField.m
//  Martin
//
//  Created by Tomislav Grbin on 9/14/13.
//
//

#import "PlayerStatusTextField.h"
#import "PlaylistItem.h"

@interface PlayerStatusTextField()
@property (nonatomic, strong) NSDictionary *textAttributes;
@end

@implementation PlayerStatusTextField

static NSString * const kStoppedText = @"--";

static NSString * const kPathSeparator = @" / ";
static NSString * const kTagSeparator = @" - ";

static const int kPlayingOpacity = 70;
static const int kStoppedOpacity = 40;

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    self.textAttributes = [NSDictionary dictionaryWithObject:self.font
                                                      forKey:NSFontAttributeName];
  }
  return self;
}

- (void)setStatus:(TextFieldStatus)status {
  _status = status;

  int opacity = (status == kTextFieldStatusPlaying)? kPlayingOpacity: kStoppedOpacity;
  self.textColor = [NSColor colorWithCalibratedWhite:0 alpha:opacity / 100.];

  [self updateDisplayText];
}

- (void)setPlaylistItem:(PlaylistItem *)playlistItem {
  _playlistItem = playlistItem;
  [self updateDisplayText];
}

- (void)updateDisplayText {
  NSString *text = kStoppedText;

  if (_status != kTextFieldStatusStopped && _playlistItem != nil) {
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

@end
