//
//  PlaylistTableView.m
//  Martin
//
//  Created by Tomislav Grbin on 11/21/12.
//
//

#import "PlaylistTableView.h"
#import "TableSongsDataSource.h"
#import "MartinAppDelegate.h"
#import "PlaylistManager.h"

@implementation PlaylistTableView

- (void)keyDown:(NSEvent *)event {
  BOOL eventProcessed = NO;
  
  if (event.type == NSKeyDown) {
    NSString *pressedChars = event.characters;
    if (pressedChars.length == 1) {
      unichar pressedUnichar = [pressedChars characterAtIndex:0];
      NSLog(@"%d", pressedUnichar);
      
      eventProcessed = YES;
      switch (pressedUnichar) {
        case NSDeleteCharacter:
        case NSDeleteFunctionKey:
        case NSDeleteCharFunctionKey:
          [((TableSongsDataSource *)self.dataSource) deleteSelectedItems];
          break;
        case NSEnterCharacter:
        case NSNewlineCharacter:
        case NSCarriageReturnCharacter:
          [((MartinAppDelegate *)[[NSApplication sharedApplication] delegate]).playlistManager enterPressed];
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
