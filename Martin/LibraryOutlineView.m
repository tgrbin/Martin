//
//  LibraryOutlineView.m
//  Martin
//
//  Created by Tomislav Grbin on 11/21/12.
//
//

#import "LibraryOutlineView.h"
#import "PlaylistTableManager.h"

@implementation LibraryOutlineView

- (void)keyDown:(NSEvent *)event {
  BOOL eventProcessed = NO;
  
  if (event.type == NSKeyDown) {
    NSString *pressedChars = event.characters;
    if (pressedChars.length == 1) {
      unichar pressedUnichar = [pressedChars characterAtIndex:0];
      
      eventProcessed = YES;
      switch (pressedUnichar) {
        case NSEnterCharacter:
        case NSNewlineCharacter:
        case NSCarriageReturnCharacter:
          {
            NSMutableArray *selectedItems = [NSMutableArray new];
            for (NSInteger row = self.selectedRowIndexes.firstIndex; row != NSNotFound; row = [self.selectedRowIndexes indexGreaterThanIndex:row]) {
              [selectedItems addObject:[self itemAtRow:row]];
            }
            [[PlaylistTableManager sharedManager] addTreeNodesToPlaylist:selectedItems];
          }
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
