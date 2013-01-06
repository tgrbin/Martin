//
//  ShortcutBinder.m
//  Martin
//
//  Created by Tomislav Grbin on 1/6/13.
//
//

#import "ShortcutBinder.h"
#import <objc/runtime.h>

@implementation ShortcutBinder

static NSMutableArray *bindings;

+ (void)bindControl:(NSControl *)control andKey:(MartinKey)key toTarget:(id)target andAction:(SEL)action {
  [bindings addObject:@[control, @(key), target, NSStringFromSelector(action)]];
}

+ (void)initialize {
  bindings = [NSMutableArray new];
  hookClass([NSTableView class]);
}

static void hookMethod(SEL sel, Class cls, Method newMethod, SEL selOriginal) {
  Method origMethod = class_getInstanceMethod(cls, sel);
  IMP origImp_stret = class_getMethodImplementation_stret(cls, sel);
  class_replaceMethod(cls, sel, method_getImplementation(newMethod), method_getTypeEncoding(origMethod));
  class_addMethod(cls, selOriginal, origImp_stret, method_getTypeEncoding(origMethod));
}

static void hookClass(Class cls) {
  hookMethod(@selector(keyDown:),
             cls,
             class_getInstanceMethod([ShortcutBinder class], @selector(keyDown:)),
             @selector(__martin__keyDown:));
}

- (void)__martin__keyDown:(NSEvent *)event {}

#pragma mark - key down

// in this method, self is nscontrol that received the event
- (void)keyDown:(NSEvent *)event {
  MartinKey key = keyFromEvent(event);

  if (key != kMartinKeyNotRelevant) {
    for (NSArray *binding in bindings) {
      if (self != binding[0]) continue;
      if ([binding[1] intValue] != key) continue;

      [binding[2] performSelector:NSSelectorFromString(binding[3])];
      return;
    }
  }

  [self __martin__keyDown:event];
}

static MartinKey keyFromEvent(NSEvent *event) {
  if (event.type == NSKeyDown) {
    NSString *pressedChars = event.characters;
    if (pressedChars.length == 1) {
      unichar pressedUnichar = [pressedChars characterAtIndex:0];

      switch (pressedUnichar) {
        case NSDeleteCharacter:
        case NSDeleteFunctionKey:
        case NSDeleteCharFunctionKey:
          return kMartinKeyDelete;
        case NSEnterCharacter:
        case NSNewlineCharacter:
        case NSCarriageReturnCharacter:
          return kMartinKeyEnter;
      }
    }
  }

  return kMartinKeyNotRelevant;
}

@end
