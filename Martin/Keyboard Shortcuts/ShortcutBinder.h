//
//  ShortcutBinder.h
//  Martin
//
//  Created by Tomislav Grbin on 1/6/13.
//
//

#import <Foundation/Foundation.h>

@interface ShortcutBinder : NSObject

typedef enum {
  kMartinKeyNotRelevant,
  kMartinKeyEnter,
  kMartinKeyDelete,
  kMartinKeyCmdEnter,
  kMartinKeySelectAll,
  kMartinKeyQueueItems,
  kMartinKeySelectArtist,
  kMartinKeySelectAlbum,
  kMartinKeySearch,
  kMartinKeyCrop,
  kMartinKeyShuffle,
  kMartinKeyLeft,
  kMartinKeyRight
} MartinKey;

+ (void)bindControl:(NSControl *)control toTarget:(id)target withBindings:(NSDictionary *)bindings;
+ (void)bindControl:(NSControl *)control andKey:(MartinKey)key toTarget:(id)target andAction:(SEL)action;
+ (void)bindControl:(NSControl *)control andKey:(MartinKey)key toTarget:(id)target andAction:(SEL)action withObject:(id)obj;

+ (MartinKey)martinKeyForEvent:(NSEvent *)event;

@end
