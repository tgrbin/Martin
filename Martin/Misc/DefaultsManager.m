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
    @(kDefaultsKeyMediaKeysEnabled): @YES,
    @(kDefaultsKeyStreams): @[
//        @{
//          @"name": @"Antena Zagreb",
//          @"url": @"http://173.192.137.34:8050"
//          }, @{
//          @"name": @"Banja Luka Big Radio 1",
//          @"url": @"http://62.212.73.51:8008"
//          }, @{
//          @"name": @"Banja Luka Big Radio 2",
//          @"url": @"http://62.212.73.51:8016/bigradio"
//          }, @{
//          @"name": @"Banja Luka Big Radio 3",
//          @"url": @"http://62.212.73.51:8004"
//          }, @{
//          @"name": @"Minessota public radio",
//          @"url": @"http://currentstream1.publicradio.org:80/"
//          }, @{
//          @"name": @"Ministry Of Sound LIVE",
//          @"url": @"http://mos-ios.ministryofsound.com/mosi.aac"
//          }, @{
//          @"name": @"Nofm",
//          @"url": @"http://gal.bitsyu.net:8002"
//          }, @{
//          @"name": @"Otvoreni Radio",
//          @"url": @"http://87.98.250.149:8002/"
//          }, @{
//          @"name": @"Radio 101",
//          @"url": @"http://live.radio101.hr:80/"
//          }, @{
//          @"name": @"Radio 101 Rock",
//          @"url": @"http://live.radio101.hr:7005"
//          }, @{
//          @"name": @"Radio 808",
//          @"url": @"http://test.radio808.info:8003"
//          }, @{
//          @"name": @"Radio Korcula",
//          @"url": @"http://radio.ikorcula.net:7845/"
//          }, @{
//          @"name": @"Radio Moslavina",
//          @"url": @"http://144.76.172.23:7049"
//          }, @{
//          @"name": @"Radio Sava",
//          @"url": @"http://193.198.16.73:8000"
//          }, @{
//          @"name": @"Radio Student",
//          @"url": @"http://161.53.122.184:8000/AAC128.aac"
//          }, @{
//          @"name": @"Soma.FM - 80sUnderground",
//          @"url": @"http://sfstream1.somafm.com:8884"
//          }, @{
//          @"name": @"Soma.FM - Bagel",
//          @"url": @"http://sfstream1.somafm.com:9090"
//          }, @{
//          @"name": @"Soma.FM - CliqHop",
//          @"url": @"http://mp2.somafm.com:2668"
//          }, @{
//          @"name": @"Soma.FM - Covers",
//          @"url": @"http://sfstream1.somafm.com:8700"
//          }, @{
//          @"name": @"Soma.FM - Doomed",
//          @"url": @"http://sfstream1.somafm.com:8300"
//          }, @{
//          @"name": @"Soma.FM - DroneZone",
//          @"url": @"http://mp4.somafm.com:8100"
//          }, @{
//          @"name": @"Soma.FM - IllionisStreet",
//          @"url": @"http://sfstream1.somafm.com:8500"
//          }, @{
//          @"name": @"Soma.FM - Indie Pop",
//          @"url": @"http://sfstream1.somafm.com:8070"
//          }, @{
//          @"name": @"Soma.FM - Indie Pop Rock",
//          @"url": @"http://sfstream1.somafm.com:8090"
//          }, @{
//          @"name": @"Soma.FM - Indiefolk",
//          @"url": @"http://sfstream1.somafm.com:7400"
//          }, @{
//          @"name": @"Soma.FM - Lush",
//          @"url": @"http://mp4.somafm.com:8800"
//          }, @{
//          @"name": @"Soma.FM - PopTron",
//          @"url": @"http://sfstream1.somafm.com:2200"
//          }, @{
//          @"name": @"Soma.FM - SecretAgent",
//          @"url": @"http://mp2.somafm.com:9016"
//          }, @{
//          @"name": @"Soma.FM - SonicUniverse",
//          @"url": @"http://mp2.somafm.com:8604"
//          }, @{
//          @"name": @"Soma.FM - Spacestation",
//          @"url": @"http://mp2.somafm.com:2666"
//          }, @{
//          @"name": @"Soma.FM - Suburbs Of Goa",
//          @"url": @"http://sfstream1.somafm.com:8850"
//          }, @{
//          @"name": @"Soma.FM - beatBender",
//          @"url": @"http://sfstream1.somafm.com:8384"
//          }, @{
//          @"name": @"Soundset Plavi",
//          @"url": @"http://46.4.51.72:9000/stream"
//          }, @{
//          @"name": @"Swiss Jazz",
//          @"url": @"http://streaming.swisstxt.ch/m/rsj/mp3_128"
//          }
        ],
    @(kDefaultsKeyShowStreamsInLibraryPane): @YES
  };
}

+ (id)objectForKey:(DefaultsKey)key {
  id o = [[NSUserDefaults standardUserDefaults] objectForKey:[self stringForKey:key]];
  return o ?: defaultValues[@(key)];
}

+ (void)setObject:(id)o forKey:(DefaultsKey)key {
  if (o == nil) {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self stringForKey:key]];
  } else {
    [[NSUserDefaults standardUserDefaults] setObject:o forKey:[self stringForKey:key]];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

+ (NSString *)stringForKey:(DefaultsKey)key {
  return [NSString stringWithFormat:@"MartinKey%d", key];
}

@end
