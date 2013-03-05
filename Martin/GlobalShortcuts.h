//
//  GlobalShortcuts.h
//  Martin
//
//  Created by Tomislav Grbin on 1/29/13.
//
//

#import <Foundation/Foundation.h>
#import "SRCommon.h"

#define kNumberOfGlobalShortcuts 4

typedef enum {
  kGlobalShortcutActionShowOrHide,
  kGlobalShortcutActionPlayOrPause,
  kGlobalShrotcutActionPrev,
  kGlobalShortcutActionNext
} GlobalShortcutAction;

@interface GlobalShortcuts : NSObject

+ (void)setupShortcuts;

+ (KeyCombo)shortcutForAction:(GlobalShortcutAction)action;
+ (void)setShortcut:(KeyCombo)shortcut forAction:(GlobalShortcutAction)action;

+ (void)resetToDefaults;

@end
