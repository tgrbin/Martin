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
@property (nonatomic, assign) BOOL mouseDown;
@end

@implementation MartinSliderCell

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    self.knobOnImage = [NSImage imageNamed:@"handle_h"];
    self.knobOffImage = [NSImage imageNamed:@"handle"];
  }
  return self;
}

- (void)drawKnob:(NSRect)knobRect {
  NSImage *image = _mouseDown? _knobOnImage: _knobOffImage;
  [image drawAtPoint:NSMakePoint(knobRect.origin.x, knobRect.origin.y)
            fromRect:NSZeroRect
           operation:NSCompositeSourceOver
            fraction:1];
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
  self.mouseDown = YES;
  return [super startTrackingAt:startPoint inView:controlView];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
  self.mouseDown = NO;
  [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
}

@end
