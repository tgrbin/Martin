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
  kMartinKeyCmdDown,
  kMartinKeySelectAll,
  kMartinKeyQueueItems,
  kMartinKeySelectArtist,
  kMartinKeySelectAlbum,
  kMartinKeySearch,
  kMartinKeyLeft,
  kMartinKeyRight,
  kMartinKeyCrop,
  kMartinKeyShuffle,
  kMartinKeyPlayPause
} MartinKey;

+ (void)bindControl:(NSControl *)control toTarget:(id)target withBindings:(NSDictionary *)bindings;
+ (void)bindControl:(NSControl *)control andKey:(MartinKey)key toTarget:(id)target andAction:(SEL)action;

+ (MartinKey)martinKeyForEvent:(NSEvent *)event;

@end