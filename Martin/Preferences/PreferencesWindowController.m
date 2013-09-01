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

@interface PreferencesWindowController() <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate, NSToolbarDelegate>
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
    for (PreferencesViewController *vc in controllers) {
      [titles addObject:vc.title];
      vc.window = self.window;
    }

    for (int i = 0; i < titles.count; ++i) {
      [_toolbar insertItemWithItemIdentifier:titles[i] atIndex:i];
    }

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

- (void)showAddFolder {
  [(LibraryPreferencesViewController *)controllers[0] showAddFolder];
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

  PreferencesViewController *oldVC = controllers[oldIndex];
  PreferencesViewController *newVC = controllers[newIndex];

  float deltaH = newVC.height - oldVC.height;
  NSRect newWindowFrame = self.window.frame;
  newWindowFrame.size.height += deltaH;
  newWindowFrame.origin.y -= deltaH;


  NSView *view = newVC.view;
  view.frame = CGRectMake(view.frame.origin.x,
                          view.frame.origin.y,
                          view.frame.size.width,
                          newVC.height);

  newVC.view.alphaValue = 0;

  [NSAnimationContext beginGrouping];
  [[NSAnimationContext currentContext] setDuration:0.2];
  [[oldVC.view animator] setAlphaValue:0];
  [[newVC.view animator] setAlphaValue:1];
  [[self.window animator] setFrame:newWindowFrame display:NO];
  [NSAnimationContext endGrouping];

  [_tabView selectTabViewItemAtIndex:newIndex];
  self.window.title = titles[newIndex];
}

@end
