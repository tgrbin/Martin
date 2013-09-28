//
//  MMAttachedTabBarButton.m
//  MMTabBarView
//
//  Created by Michael Monscheuer on 9/5/12.
//
//

#import "MMAttachedTabBarButton.h"

#import "MMAttachedTabBarButtonCell.h"
#import "MMTabDragAssistant.h"
#import "MMTabStyle.h"
#import "NSView+MMTabBarViewExtensions.h"

#import "PlaylistTabBarItem.h"
#import "MartinAppDelegate.h"
#import "Playlist.h"

@interface MMAttachedTabBarButton (/*Private*/) <NSTextFieldDelegate>

- (MMAttachedTabBarButton *)_selectedAttachedTabBarButton;
- (NSRect)_draggingRect;

@end

@implementation MMAttachedTabBarButton {
  BOOL renamingTitle;
}

@synthesize tabViewItem = _tabViewItem;
@dynamic slidingFrame;
@synthesize isInAnimatedSlide = _isInAnimatedSlide;
@synthesize isInDraggedSlide = _isInDraggedSlide;
@dynamic isSliding;
@dynamic isOverflowButton;

+ (void)initialize {
  [super initialize];
}

+ (Class)cellClass {
  return [MMAttachedTabBarButtonCell class];
}

- (id)initWithFrame:(NSRect)frame tabViewItem:(NSTabViewItem *)anItem {

  self = [super initWithFrame:frame];
  if (self) {
    _tabViewItem = [anItem retain];
    _isInAnimatedSlide = NO;
    _isInDraggedSlide = NO;
  }

  return self;
}

- (id)initWithFrame:(NSRect)frame {

  NSAssert(FALSE,@"please use designated initializer -initWithFrame:tabViewItem:");

  [self release];
  return nil;
}

- (void)dealloc
{
  [_tabViewItem release], _tabViewItem = nil;
  [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];
}

- (MMAttachedTabBarButtonCell *)cell {
  return (MMAttachedTabBarButtonCell *)[super cell];
}

- (void)setCell:(MMAttachedTabBarButtonCell *)aCell {
  [super setCell:aCell];
}

-(void)viewWillDraw {

  NSView *superview = [self superview];
  [superview setNeedsDisplayInRect:[superview bounds]];

  [super viewWillDraw];
}

#pragma mark -
#pragma mark Accessors

- (NSRect)slidingFrame {
  @synchronized(self) {
    return [self frame];
  }
}

- (void)setSlidingFrame:(NSRect)aRect {
  @synchronized(self) {
    aRect.origin.y = [self frame].origin.y;
    [self setFrame:aRect];
  }
}

- (BOOL)isSliding {
  return _isInDraggedSlide || _isInAnimatedSlide;
}

- (void)setTitle:(NSString *)aString {
  [super setTitle:aString];

  // additionally synchronize label of tab view item if appropriate
  if (_tabViewItem && [_tabViewItem respondsToSelector:@selector(label)]) {
    if (![[_tabViewItem label] isEqualToString:aString]) {
      [_tabViewItem setLabel:aString];
    }
  }
}

#pragma mark -
#pragma mark Dividers

- (BOOL)shouldDisplayLeftDivider {

  if ([self isSliding] || ([self tabState] & MMTab_PlaceholderOnLeft))
    return YES;

  return [super shouldDisplayLeftDivider];
}

- (BOOL)shouldDisplayRightDivider {

  if ([self isOverflowButton])
    return NO;

  return YES;
}

#pragma mark -
#pragma mark Interfacing Cell

- (BOOL)isOverflowButton {
  return [[self cell] isOverflowButton];
}

- (void)setIsOverflowButton:(BOOL)value {
  [[self cell] setIsOverflowButton:value];
}

#pragma mark -
#pragma mark Event Handling

- (void)mouseDown:(NSEvent *)theEvent {
  MMAttachedTabBarButton *previousSelectedButton = [self _selectedAttachedTabBarButton];

  MMTabBarView *tabBarView = [self tabBarView];

  // select immediately
  if ([tabBarView selectsTabsOnMouseDown]) {
    if (self != previousSelectedButton) {
      [previousSelectedButton setState:NSOffState];
      [self setState:NSOnState];
      [self sendAction:[self action] to:[self target]];
    }
  }

  // eventually begin dragging of button
  if ([tabBarView shouldStartDraggingAttachedTabBarButton:self withMouseDownEvent:theEvent]) {
    [tabBarView startDraggingAttachedTabBarButton:self withMouseDownEvent:theEvent];
  }
}

- (void)mouseUp:(NSEvent *)theEvent {
  MMTabBarView *tabBarView = [self tabBarView];

  NSPoint mouseUpPoint = [theEvent locationInWindow];
  NSPoint mousePt = [self convertPoint:mouseUpPoint fromView:nil];

  if (NSMouseInRect(mousePt, [self bounds], [self isFlipped])) {
    if (![tabBarView selectsTabsOnMouseDown]) {
      MMAttachedTabBarButton *previousSelectedButton = [self _selectedAttachedTabBarButton];
      [previousSelectedButton setState:NSOffState];
      [self setState:NSOnState];
      [self sendAction:[self action] to:[self target]];
    }

    if (theEvent.clickCount > 1) {
      [self beginRenaming];
    }
  }
}

#pragma mark - Martin renaming support

static const int kRenameFieldTag = 601;

- (void)beginRenaming {
  PlaylistTabBarItem *item = self.tabViewItem.identifier;

  if ([self viewWithTag:kRenameFieldTag] != nil || item.playlist.isQueue == YES) {
    return;
  }

  renamingTitle = YES;

  NSTextField *renameField = [[NSTextField alloc] initWithFrame:NSOffsetRect(NSInsetRect(self.bounds, 20, 0), 0, 3)];
  renameField.tag = kRenameFieldTag;
  renameField.delegate = self;
  renameField.focusRingType = NSFocusRingTypeNone;

  NSTextFieldCell *cell = renameField.cell;
  cell.editable = YES;
  cell.bezeled = NO;
  cell.bordered = NO;
  cell.drawsBackground = NO;
  cell.usesSingleLineMode = YES;
  cell.alignment = NSCenterTextAlignment;
  cell.wraps = YES;
  cell.lineBreakMode = NSLineBreakByTruncatingTail;
  cell.font = self.cell.font;

  cell.stringValue = item.title;

  // this hides tab's title but leaves it's size intact
  self.attributedTitle = [[NSAttributedString alloc] initWithString:@""];

  [self addSubview:renameField];

  [[MartinAppDelegate get].window makeFirstResponder:renameField];
}

- (void)endRenaming {
  renamingTitle = NO;
  NSTextField *renameField = [self viewWithTag:kRenameFieldTag];
  [renameField removeFromSuperview];
}

- (void)cancelOperation:(id)sender {
  PlaylistTabBarItem *item = self.tabViewItem.identifier;
  self.title = item.title;
  [self endRenaming];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
  if (renamingTitle == NO) {
    return YES;
  }

  PlaylistTabBarItem *item = self.tabViewItem.identifier;
  item.title = fieldEditor.string;
  [self endRenaming];
  return YES;
}

#pragma mark - Martin now playing support

- (void)updateNowPlayingIndicator {
  PlaylistTabBarItem *item = self.tabViewItem.identifier;
  Playlist *playlist = item.playlist;
  BOOL nowPlaying = [[MartinAppDelegate get].player nowPlayingItemFromPlaylist:playlist];

  CGFloat fontSize = self.cell.font.pointSize;
  NSFont *font = nowPlaying? [NSFont boldSystemFontOfSize:fontSize]: [NSFont systemFontOfSize:fontSize];
  self.cell.font = font;
}

#pragma mark -
#pragma mark Drag Support

- (NSRect)draggingRect {

  id <MMTabStyle> style = [self style];
  MMTabBarView *tabBarView = [self tabBarView];

  NSRect draggingRect = NSZeroRect;

  if (style && [style respondsToSelector:@selector(dragRectForTabButton:ofTabBarView:)]) {
    draggingRect = [style draggingRectForTabButton:self ofTabBarView:tabBarView];
  } else {
    draggingRect = [self _draggingRect];
  }

  return draggingRect;
}

- (NSImage *)dragImage {

  // assure that we will draw the tab bar contents correctly
  [self setFrame:[self stackingFrame]];

  MMTabBarView *tabBarView = [self tabBarView];

  NSRect draggingRect = [self draggingRect];

	[tabBarView lockFocus];
  [tabBarView display];  // forces update to ensure that we get current state
	NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:draggingRect] autorelease];
	[tabBarView unlockFocus];
	NSImage *image = [[[NSImage alloc] initWithSize:[rep size]] autorelease];
	[image addRepresentation:rep];
	NSImage *returnImage = [[[NSImage alloc] initWithSize:[rep size]] autorelease];
	[returnImage lockFocus];
  [image drawAtPoint:NSMakePoint(0.0, 0.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[returnImage unlockFocus];
	if (![[self indicator] isHidden]) {
		NSImage *pi = [[NSImage alloc] initByReferencingFile:[[MMTabBarView bundle] pathForImageResource:@"pi"]];
		[returnImage lockFocus];
		NSPoint indicatorPoint = NSMakePoint([self frame].size.width - MARGIN_X - kMMTabBarIndicatorWidth, MARGIN_Y);
    [pi drawAtPoint:indicatorPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[returnImage unlockFocus];
		[pi release];
	}
	return returnImage;
}

#pragma mark -
#pragma mark Animation Support

- (void)slideAnimationWillStart {
  _isInAnimatedSlide = YES;
}

- (void)slideAnimationDidEnd {
  _isInAnimatedSlide = NO;
}

#pragma mark -
#pragma mark Private Methods

- (MMAttachedTabBarButton *)_selectedAttachedTabBarButton {

  MMTabBarView *tabBarView = [self enclosingTabBarView];
  return [tabBarView selectedAttachedButton];
}

- (NSRect)_draggingRect {
  return [self frame];
}

@end
