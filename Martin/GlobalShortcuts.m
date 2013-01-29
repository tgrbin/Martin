//
//  GlobalShortcuts.m
//  Martin
//
//  Created by Tomislav Grbin on 1/29/13.
//
//

#import "MartinAppDelegate.h"
#import "GlobalShortcuts.h"
#import <Carbon/Carbon.h>
#import "Player.h"

@implementation GlobalShortcuts

+ (void)initShortcuts {
  EventHotKeyRef hkRef;
  EventHotKeyID hkID;
  EventTypeSpec eventType;
  eventType.eventClass = kEventClassKeyboard;
  eventType.eventKind = kEventHotKeyPressed;

  InstallApplicationEventHandler(&hotkeyHandler, 1, &eventType, NULL, NULL);

  hkID.signature = 'play';
  hkID.id = 1;
  RegisterEventHotKey(7, shiftKey+cmdKey, hkID, GetApplicationEventTarget(), 0, &hkRef);

  hkID.signature = 'prev';
  hkID.id = 2;
  RegisterEventHotKey(13, shiftKey+cmdKey, hkID, GetApplicationEventTarget(), 0, &hkRef);

  hkID.signature = 'next';
  hkID.id = 3;
  RegisterEventHotKey(14, shiftKey+cmdKey, hkID, GetApplicationEventTarget(), 0, &hkRef);

  hkID.signature = 'show';
  hkID.id = 4;
  RegisterEventHotKey(46, shiftKey+cmdKey, hkID, GetApplicationEventTarget(), 0, &hkRef);
}

static OSStatus hotkeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
  EventHotKeyID hkCom;
  GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hkCom), NULL, &hkCom);

  Player *player = [MartinAppDelegate get].player;
  int _id = hkCom.id;

  if (_id == 1 ) [player playOrPause];
  else if (_id == 2) [player prev];
  else if (_id == 3) [player next];
  else if (_id == 4) [[MartinAppDelegate get] toggleMartinVisible];

  return noErr;
}

@end
