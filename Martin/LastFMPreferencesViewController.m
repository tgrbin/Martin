//
//  LastFMPreferencesViewController.m
//  Martin
//
//  Created by Tomislav Grbin on 3/30/13.
//
//

#import "LastFMPreferencesViewController.h"
#import "LastFM.h"

typedef enum {
  kStateNoToken,
  kStateNoSessionKey,
  kStateScrobbling
} State;

@interface LastFMPreferencesViewController ()
@property (strong) IBOutlet NSProgressIndicator *activityIndicator;
@property (strong) IBOutlet NSButton *button;
@property (strong) IBOutlet NSTextField *textField;

@property (nonatomic, assign) State state;
@end

@implementation LastFMPreferencesViewController

- (id)init {
  if (self = [super init]) {
    self.title = @"LastFM";
  }
  return self;
}

- (void)awakeFromNib {
  self.state = [LastFM isScrobbling]? kStateScrobbling: kStateNoToken;
}

#pragma mark - actions

- (IBAction)buttonPressed:(id)sender {
  if (_state == kStateNoToken) {
    [self getToken];
  } else if (_state == kStateNoSessionKey) {
    [self getSessionKey];
  } else if (_state == kStateScrobbling) {
    [self resetSessionKey];
  }
}

- (void)getToken {
  [self showSpinner];
  [LastFM getAuthURLWithBlock:^(NSString *url) {
    [self hideSpinner];

    if (url) {
      self.state = kStateNoSessionKey;
      [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    } else {
      [self showAlertWithMsg:@"Sorry, failed to ask LastFM for access."];
    }
  }];
}


- (void)getSessionKey {
  [self showSpinner];
  [LastFM getSessionKey:^(BOOL success) {
    [self hideSpinner];

    if (success == YES) {
      self.state = kStateScrobbling;
    } else {
      self.state = kStateNoToken;
      [self showAlertWithMsg:@"Sorry, failed to get permission to scrobble from LastFM."];
    }
  }];
}

- (void)resetSessionKey {
  [LastFM stopScrobbling];
  self.state = kStateNoToken;
  [self showAlertWithMsg:@"Martin is no longer scrobbling."];
}

#pragma mark - util

- (void)setState:(State)state {
  _state = state;
  [self updateUI];
}

- (void)updateUI {
  static NSString * const buttonTitles[] = { @"Go to LastFM", @"Start scrobbling", @"Stop scrobbling" };
  static NSString * const messages[] = {
    @"To start scrobbling, Martin must be allowed to access your account.\nPressing below will go to www.last.fm and ask you to login and allow access.",
    @"When you're done, press start scrobbling.",
    @"Martin is scrobbling happily."
  };

  _button.title = buttonTitles[_state];
  _textField.stringValue = messages[_state];
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

  [alert beginSheetModalForWindow:self.window
                    modalDelegate:nil
                   didEndSelector:nil
                      contextInfo:nil];
}

@end
