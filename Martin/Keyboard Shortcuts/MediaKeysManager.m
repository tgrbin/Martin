//
//  MediaKeysManager.m
//  Martin
//
//  Created by Tomislav Grbin on 25/01/14.
//
//

#import "MediaKeysManager.h"
#import "SPMediaKeyTap.h"
#import "MartinAppDelegate.h"
#import "Player.h"
#import "DefaultsManager.h"

@implementation MediaKeysManager {
  SPMediaKeyTap *mediaKeyTap;
}

static MediaKeysManager *instance;

+ (void)initialize {
  instance = [MediaKeysManager new];
}

+ (MediaKeysManager *)shared {
  return instance;
}

- (id)init {
  if (self = [super init]) {
    // taken from SPMediaKeyTap example app
    // Register defaults for the whitelist of apps that want to use media keys
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     @{
       kMediaKeyUsingBundleIdentifiersDefaultsKey: [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers]
       }];
    
    _mediaKeysEnabled = [[DefaultsManager objectForKey:kDefaultsKeyMediaKeysEnabled] boolValue];
    
    mediaKeyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
    if (_mediaKeysEnabled && [SPMediaKeyTap usesGlobalMediaKeyTap]) {
      [mediaKeyTap startWatchingMediaKeys];
    }
  }
  return self;
}

- (void)setMediaKeysEnabled:(BOOL)mediaKeysEnabled {
  _mediaKeysEnabled = mediaKeysEnabled;
  
  [DefaultsManager setObject:@(mediaKeysEnabled)
                      forKey:kDefaultsKeyMediaKeysEnabled];
  
  if (_mediaKeysEnabled == YES) {
    [mediaKeyTap startWatchingMediaKeys];
  } else {
    [mediaKeyTap stopWatchingMediaKeys];
  }
}

- (void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event {
	NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
  
	// here be dragons...
	int keyCode = (([event data1] & 0xFFFF0000) >> 16);
	int keyFlags = ([event data1] & 0x0000FFFF);
	BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
  int keyRepeat = (keyFlags & 0x1);
	
	if (keyIsPressed && keyRepeat == 0) {
    Player *player = [MartinAppDelegate get].player;
    
		switch (keyCode) {
			case NX_KEYTYPE_PLAY:
        [player playOrPause];
				break;
			case NX_KEYTYPE_FAST:
        [player next];
				break;
			case NX_KEYTYPE_REWIND:
        [player prev];
				break;
			default:
				break;
		}
	}
}

@end
