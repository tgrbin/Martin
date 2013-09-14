//
//  MartinSlider.m
//  Martin
//
//  Created by Tomislav Grbin on 9/14/13.
//
//

#import "MartinSlider.h"

@implementation MartinSlider

- (void)setNeedsDisplayInRect:(NSRect)invalidRect {
  [super setNeedsDisplayInRect:[self bounds]];
}

- (void)setEnabled:(BOOL)flag {
  [super setEnabled:flag];
  self.alphaValue = flag? 1: 0.7;
}

@end
