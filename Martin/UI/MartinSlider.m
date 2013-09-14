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

@end
