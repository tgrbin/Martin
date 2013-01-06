//
//  PlaylistsTableView.m
//  Martin
//
//  Created by Tomislav Grbin on 1/5/13.
//
//

#import "PlaylistsTableView.h"
#import "PlaylistManager.h"

@implementation PlaylistsTableView

- (void)keyDown:(NSEvent *)event {
  BOOL eventProcessed = NO;

  if (event.type == NSKeyDown) {
    NSString *pressedChars = event.characters;
    if (pressedChars.length == 1) {
      unichar pressedUnichar = [pressedChars characterAtIndex:0];

      eventProcessed = YES;
      switch (pressedUnichar) {
        case NSDeleteCharacter:
        case NSDeleteFunctionKey:
        case NSDeleteCharFunctionKey:
          [[PlaylistManager sharedManager] deleteSelectedPlaylists];
          break;
        case NSEnterCharacter:
        case NSNewlineCharacter:
        case NSCarriageReturnCharacter:
          [[PlaylistManager sharedManager] startPlaylingSelectedPlaylist];
          break;
        default:
          eventProcessed = NO;
          break;
      }
    }
  }

  if (!eventProcessed) [super keyDown:event];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
  [super draggingExited:sender];
  [[PlaylistManager sharedManager] dragExited];
}

@end
