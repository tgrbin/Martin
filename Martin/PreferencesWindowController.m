//
//  PreferencesWindowController.m
//  Martin
//
//  Created by Tomislav Grbin on 11/16/12.
//
//

#import "PreferencesWindowController.h"
#import "PreferencesViewController.h"

#import "LibraryPreferencesViewController.h"
#import "LastFMPreferencesViewController.h"
#import "ShortcutsPreferencesViewController.h"

@interface PreferencesWindowController()
@property (strong) IBOutlet NSToolbar *toolbar;
@property (strong) IBOutlet NSTabView *tabView;
@end

@implementation PreferencesWindowController {
  NSArray *controllers;
  NSMutableArray *titles;
}

- (id)init {
  return (self = [super initWithWindowNibName:@"PreferencesWindowController"]);
}

- (void)awakeFromNib {
  if (_toolbar) {
    controllers = @[
      [LibraryPreferencesViewController new],
      [LastFMPreferencesViewController new],
      [ShortcutsPreferencesViewController new]
    ];

    titles = [NSMutableArray new];
    for (PreferencesViewController *vc in controllers) [titles addObject:vc.title];
    for (int i = 0; i < titles.count; ++i) [_toolbar insertItemWithItemIdentifier:titles[i] atIndex:i];

    for (int i = 0; i < titles.count; ++i) {
      NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:titles[i]];
      item.label = titles[i];
      item.view = [controllers[i] view];
      [_tabView addTabViewItem:item];
    }

    _toolbar.selectedItemIdentifier = titles[0];
    self.window.title = titles[0];
  }
}

#pragma mark - toolbar delegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
  item.label = itemIdentifier;
  item.tag = [titles indexOfObject:itemIdentifier];
  item.target = self;
  item.action = @selector(toolbarItemPressed:);
  return item;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  return titles;
}

- (void)toolbarItemPressed:(NSToolbarItem *)sender {
  NSInteger oldIndex = [titles indexOfObject:[_tabView selectedTabViewItem].identifier];
  NSInteger newIndex = sender.tag;

  self.window.title = titles[newIndex];

  NSInteger oldH = [controllers[oldIndex] height];
  NSInteger newH = [controllers[newIndex] height];

  float deltaH = newH - oldH;

  NSRect windowFrame = self.window.frame;
  windowFrame.size.height += deltaH;
  windowFrame.origin.y -= deltaH;

  [_tabView selectTabViewItemAtIndex:newIndex];
  NSView *view = ((NSViewController *)controllers[newIndex]).view;
  view.frame = CGRectMake(view.frame.origin.x,
                          view.frame.origin.y,
                          view.frame.size.width,
                          newH);

  [self.window setFrame:windowFrame display:YES animate:YES];
}

@end
