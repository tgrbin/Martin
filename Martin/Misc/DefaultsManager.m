//
//  DefaultsManager.m
//  Martin
//
//  Created by Tomislav Grbin on 12/27/12.
//
//

#import "DefaultsManager.h"

@implementation DefaultsManager

static NSDictionary *defaultValues;

+ (void)initialize {
  defaultValues = @{
    @(kDefaultsKeyLastFSEvent): @(kFSEventStreamEventIdSinceNow),
    @(kDefaultsKeyFolderWatcher): @YES,
    @(kDefaultsKeyShuffle): @NO,
    @(kDefaultsKeyRepeat): @NO,
    @(kDefaultsKeyLibraryFolders): @[],
    @(kDefaultsKeyTreeState): @[],
    @(kDefaultsKeyVolume): @0.5,
    @(kDefaultsKeyGlobalShortcuts): @{},
    @(kDefaultsKeySelectedPlaylistIndex): @0,
    @(kDefaultsKeySearchQuery): @"",
    @(kDefaultsKeyFirstRun): @YES,
    @(kDefaultsKeySeekPosition): @0,
    @(kDefaultsKeyPlayerState): @0,
    @(kDefaultsKeyMediaKeysEnabled): @YES
  };
}

+ (id)objectForKey:(DefaultsKey)key {
  id o = [[NSUserDefaults standardUserDefaults] objectForKey:[self stringForKey:key]];
  if (o == nil) return defaultValues[@(key)];
  return o;
}

+ (void)setObject:(id)o forKey:(DefaultsKey)key {
  if (o == nil) [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self stringForKey:key]];
  else {
    [[NSUserDefaults standardUserDefaults] setObject:o forKey:[self stringForKey:key]];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

+ (NSString *)stringForKey:(DefaultsKey)key {
  return [NSString stringWithFormat:@"MartinKey%d", key];
}

@end
