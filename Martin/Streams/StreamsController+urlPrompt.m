//
//  Stream+urlPrompt.m
//  Martin
//
//  Created by Tomislav Grbin on 17/08/14.
//
//

#import "StreamsController.h"

@implementation StreamsController (urlPrompt)

+ (NSString *)urlPrompt {
  // TODO: prompt looks ugly
  NSAlert *alert = [NSAlert alertWithMessageText:@"URL:"
                                   defaultButton:@"OK"
                                 alternateButton:@"Cancel"
                                     otherButton:nil
                       informativeTextWithFormat:@""];
  
  NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 24)];
  
  // TODO: allow paste with Cmd+V
  alert.accessoryView = input;
  
  NSInteger button = [alert runModal];
  if (button == NSAlertDefaultReturn) {
    [input validateEditing];
    return [input stringValue];
  } else {
    return nil;
  }
}

@end
