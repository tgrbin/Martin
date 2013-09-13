//
//  NoTemplateButtonCell.m
//  Martin
//
//  Created by Tomislav Grbin on 9/13/13.
//
//

#import "TGToggleButton.h"

@implementation TGToggleButton {
  NSInteger myCurrentValue;
}

- (void)setState:(NSInteger)value {
  if (myCurrentValue != value) {
    NSImage *tmpImage = [self.image copy];
    self.image = [self.alternateImage copy];
    self.alternateImage = tmpImage;
    myCurrentValue = value;
  }

  [super setState:value];
}

@end
