//
//  MartinApp.m
//  Martin
//
//  Created by Tomislav Grbin on 25/01/14.
//
//

#import "MartinApp.h"
#import "SPMediaKeyTap.h"

@implementation MartinApp

// taken from SPMediaKeyTap example application
- (void)sendEvent:(NSEvent *)theEvent {
	// If event tap is not installed, handle events that reach the app instead
	BOOL shouldHandleMediaKeyEventLocally = ![SPMediaKeyTap usesGlobalMediaKeyTap];
  
	if (shouldHandleMediaKeyEventLocally
      && [theEvent type] == NSSystemDefined
      && [theEvent subtype] == SPSystemDefinedEventMediaKeys) {
		[(id)[self delegate] mediaKeyTap:nil receivedMediaKeyEvent:theEvent];
	}
  
	[super sendEvent:theEvent];
}

@end
