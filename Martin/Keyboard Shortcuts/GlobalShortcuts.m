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
#import "PlayerController.h"
#import "DefaultsManager.h"

@implementation GlobalShortcuts

static OSType signatures[] = { 'show', 'play', 'prev', 'next' };

+ (void)initialize {
  EventTypeSpec eventType;
  eventType.eventClass = kEventClassKeyboard;
  eventType.eventKind = kEventHotKeyPressed;
  InstallApplicationEventHandler(&hotkeyHandler, 1, &eventType, NULL, NULL);

  hotKeyRefsDictionary = [NSMutableDictionary new];
}

+ (void)setupShortcuts {
  for (int i = 0; i < kNumberOfGlobalShortcuts; ++i) {
    EventHotKeyID hkID;
    hkID.signature = signatures[i];
    hkID.id = i+1;

    KeyCombo keyCombo = [self shortcutForAction:i];

    if (keyCombo.code != -1) {
      EventHotKeyRef hkRef = refForAction(i);
      if (hkRef) UnregisterEventHotKey(hkRef);

      RegisterEventHotKey((int)keyCombo.code, (int)SRCocoaToCarbonFlags(keyCombo.flags), hkID, GetApplicationEventTarget(), 0, &hkRef);
      setRefForAction(i, hkRef);
    }
  }
}

#pragma mark - get and set shortcuts

+ (KeyCombo)defaultShortcutForAction:(GlobalShortcutAction)action {
  switch (action) {
    case kGlobalShortcutActionShowOrHide:
      return SRMakeKeyCombo(46, NSCommandKeyMask | NSShiftKeyMask); // m
    case kGlobalShortcutActionPlayOrPause:
      return SRMakeKeyCombo(7, NSCommandKeyMask | NSShiftKeyMask);  // x
    case kGlobalShrotcutActionPrev:
      return SRMakeKeyCombo(13, NSCommandKeyMask | NSShiftKeyMask); // w
    case kGlobalShortcutActionNext:
      return SRMakeKeyCombo(14, NSCommandKeyMask | NSShiftKeyMask); // e
  }
}

+ (KeyCombo)shortcutForAction:(GlobalShortcutAction)action {
  NSDictionary *shortcuts = [DefaultsManager objectForKey:kDefaultsKeyGlobalShortcuts];
  NSString *shortcutString = [shortcuts objectForKey:stringForAction(action)];
  if (shortcutString == nil) return [self defaultShortcutForAction:action];

  NSArray *twoNumbers = [shortcutString componentsSeparatedByString:@" "];
  return SRMakeKeyCombo([twoNumbers[0] intValue], [twoNumbers[1] intValue]);
}

+ (void)setShortcut:(KeyCombo)shortcut forAction:(GlobalShortcutAction)action {
  NSString *shortcutString = [NSString stringWithFormat:@"%ld %ld", (long)shortcut.code, (unsigned long)shortcut.flags];

  NSMutableDictionary *dict = [[DefaultsManager objectForKey:kDefaultsKeyGlobalShortcuts] mutableCopy];
  dict[stringForAction(action)] = shortcutString;
  [DefaultsManager setObject:dict forKey:kDefaultsKeyGlobalShortcuts];

  [self setupShortcuts];
}

+ (void)resetToDefaults {
  for (int i = 0; i < kNumberOfGlobalShortcuts; ++i) {
    [self setShortcut:[self defaultShortcutForAction:i] forAction:i];
  }
}

#pragma mark - event handler

static OSStatus hotkeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
  EventHotKeyID hkCom;
  GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hkCom), NULL, &hkCom);

  PlayerController *playerController = [MartinAppDelegate get].playerController;
  GlobalShortcutAction action = hkCom.id - 1;

  switch (action) {
    case kGlobalShortcutActionShowOrHide:
      [[MartinAppDelegate get] toggleMartinVisible];
      break;
    case kGlobalShortcutActionPlayOrPause:
      [playerController playOrPause];
      break;
    case kGlobalShrotcutActionPrev:
      [playerController prev];
      break;
    case kGlobalShortcutActionNext:
      [playerController next];
      break;
  }

  return noErr;
}

#pragma mark - util

static NSString *stringForAction(GlobalShortcutAction action) {
  return [NSString stringWithFormat:@"%d", action];
}

static NSMutableDictionary *hotKeyRefsDictionary;

static EventHotKeyRef refForAction(GlobalShortcutAction action) {
  NSValue *val = hotKeyRefsDictionary[@(action)];
  if (val == nil) return NULL;
  return [val pointerValue];
}

static void setRefForAction(GlobalShortcutAction action, EventHotKeyRef hkRef) {
  NSValue *val = [NSValue valueWithPointer:hkRef];
  hotKeyRefsDictionary[@(action)] = val;
}

@end
