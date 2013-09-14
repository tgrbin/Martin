//
//  PlayerStatusTextField.m
//  Martin
//
//  Created by Tomislav Grbin on 9/14/13.
//
//

#import "PlayerStatusTextField.h"


@implementation PlayerStatusTextField

static NSString * const kStoppedMessage = @"--";
static const int kPlayingOpacity = 70;
static const int kStoppedOpacity = 40;

- (void)setStatus:(TextFieldStatus)status {
  _status = status;

  int opacity = (status == kTextFieldStatusPlaying)? kPlayingOpacity: kStoppedOpacity;
  NSString *text = (status == kTextFieldStatusStopped)? kStoppedMessage: self.displayString;

  self.textColor = [NSColor colorWithCalibratedWhite:0 alpha:opacity / 100.];
  self.stringValue = text;
}

@end
