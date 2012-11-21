//
//  PlaylistTableView.m
//  Martin
//
//  Created by Tomislav Grbin on 11/21/12.
//
//

#import "PlaylistTableView.h"
#import "PlaylistTableManager.h"
#import "Player.h"

@implementation PlaylistTableView

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
          [[PlaylistTableManager sharedManager] deleteSelectedItems];
          break;
        case NSEnterCharacter:
        case NSNewlineCharacter:
        case NSCarriageReturnCharacter:
          [[Player sharedPlayer] playItemWithIndex:(int)self.selectedRow];
          break;
        default:
          eventProcessed = NO;
          break;
      }
    }
  }
  
  if (!eventProcessed) [super keyDown:event];
}

@end
