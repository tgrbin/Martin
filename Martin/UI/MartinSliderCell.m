//
//  MartinSliderCell.m
//  Martin
//
//  Created by Tomislav Grbin on 9/14/13.
//
//

#import "MartinSliderCell.h"

@interface MartinSliderCell()
@property (nonatomic, strong) NSImage *knobOffImage;
@property (nonatomic, strong) NSImage *knobOnImage;
@property (nonatomic, strong) NSImage *leftBarImage;
@property (nonatomic, strong) NSImage *barBackgroundImage;

@property (nonatomic, assign) BOOL mouseDown;
@property (nonatomic, assign) CGRect currentKnobRect;
@end

@implementation MartinSliderCell

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    self.knobOnImage = [NSImage imageNamed:@"handle_h"];
    self.knobOffImage = [NSImage imageNamed:@"handle"];
    self.leftBarImage = [NSImage imageNamed:@"progress_a"];
    self.barBackgroundImage = [NSImage imageNamed:@"progress"];
  }
  return self;
}

- (void)drawKnob:(NSRect)knobRect {
  self.currentKnobRect = knobRect;

  NSImage *image = _mouseDown? _knobOnImage: _knobOffImage;
  [image drawAtPoint:NSMakePoint(knobRect.origin.x, knobRect.origin.y)
            fromRect:NSZeroRect
           operation:NSCompositeSourceOver
            fraction:0.5];
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
  self.mouseDown = YES;
  return [super startTrackingAt:startPoint inView:controlView];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
  self.mouseDown = NO;
  [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
}

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped {
  static const int kBarY = 9;
  static const int kBarMargin = 8; // subsctracted from left and right of the bar so that knob covers the bar completely
  static const int kBarHeight = 6;

  NSRect backgroundRect = NSMakeRect(kBarMargin, kBarY, aRect.size.width - kBarMargin*2, kBarHeight);
  [_barBackgroundImage setSize:backgroundRect.size];
  [_barBackgroundImage drawInRect:backgroundRect
                    fromRect:NSZeroRect
                   operation:NSCompositeSourceOver
                    fraction:1];

  NSRect filledRect = NSMakeRect(kBarMargin, kBarY, _currentKnobRect.origin.x, kBarHeight);
  [_leftBarImage setSize:filledRect.size];
  [_leftBarImage drawInRect:filledRect
                   fromRect:NSZeroRect
                  operation:NSCompositeSourceOver
                   fraction:1];
}

- (BOOL)_usesCustomTrackImage {
  return YES;
}

@end
