//
//  DefaultsManager.h
//  Martin
//
//  Created by Tomislav Grbin on 12/27/12.
//
//

#import <Foundation/Foundation.h>

@interface DefaultsManager : NSObject

typedef enum {
  kDefaultsKeyLastFSEvent,
  kDefaultsKeyFolderWatcher,
  kDefaultsKeyShuffle,
  kDefaultsKeyRepeat,
  kDefaultsKeyLastFMSession,
  kDefaultsKeyLibraryFolders,
  kDefaultsKeyTreeState,
  kDefaultsKeyVolume,
  kDefaultsKeyGlobalShortcuts,
  kDefaultsKeySelectedPlaylistIndex,
  kDefaultsKeySearchQuery,
  kDefaultsKeyFirstRun,
  kDefaultsKeySeekPosition,
  kDefaultsKeyPlayerState,
  kDefaultsKeyMediaKeysEnabled
} DefaultsKey;

+ (id)objectForKey:(DefaultsKey)key;
+ (void)setObject:(id)o forKey:(DefaultsKey)key;

@end
