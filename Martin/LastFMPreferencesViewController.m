//
//  LastFMPreferencesViewController.m
//  Martin
//
//  Created by Tomislav Grbin on 3/30/13.
//
//

#import "LastFMPreferencesViewController.h"
#import "LastFM.h"

@interface LastFMPreferencesViewController ()
@property (strong) IBOutlet NSProgressIndicator *activityIndicator;
@end

@implementation LastFMPreferencesViewController

- (id)init {
  if (self = [super init]) {
    self.title = @"LastFM";
  }
  return self;
}

- (IBAction)getTokenPressed:(id)sender {
  [self showSpinner];
  [LastFM getAuthURLWithBlock:^(NSString *url) {
    [self hideSpinner];

    if (url == nil) {
      [self showAlertWithMsg:@"Sorry, get token failed."];
    } else {
      [self showAlertWithMsg:@"Allow Martin to scrobble in your browser, and then proceed to getting the session key"];
      [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    }
  }];
}

- (IBAction)getSessionKeyPressed:(id)sender {
  [self showSpinner];
  [LastFM getSessionKey:^(BOOL success) {
    [self hideSpinner];

    if (success == NO) {
      [self showAlertWithMsg:@"Sorry, get session key failed. Make sure you finished previous steps correctly."];
    } else {
      [self showAlertWithMsg:@"That's it! Martin should begin scrobbling now"];
    }
  }];
}

- (IBAction)resetSessionKeyPressed:(id)sender {
  [LastFM resetSessionKey];
  [self showAlertWithMsg:@"Martin is no longer scrobbling."];
}

- (void)showSpinner {
  _activityIndicator.hidden = NO;
  [_activityIndicator startAnimation:nil];
}

- (void)hideSpinner {
  _activityIndicator.hidden = YES;
  [_activityIndicator stopAnimation:nil];
}

- (void)showAlertWithMsg:(NSString *)msg {
  NSAlert *alert = [NSAlert new];
  [alert setAlertStyle:NSInformationalAlertStyle];
  [alert setMessageText:msg];

//  [alert beginSheetModalForWindow:self.window
//                    modalDelegate:nil
//                   didEndSelector:nil
//                      contextInfo:nil];
}

@end
