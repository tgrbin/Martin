//
//  ShortcutsPreferencesViewController.m
//  Martin
//
//  Created by Tomislav Grbin on 3/30/13.
//
//

#import "ShortcutsPreferencesViewController.h"
#import "ShortcutRecorder.h"
#import "GlobalShortcuts.h"

@interface ShortcutsPreferencesViewController ()
@property (strong) IBOutlet NSView *recorderControlsHolderView;
@end

@implementation ShortcutsPreferencesViewController

- (id)init {
  if (self = [super init]) {
    self.title = @"Shortcuts";
  }
  return self;
}

- (void)awakeFromNib {
  [self updateShortcutControls];
}

- (void)updateShortcutControls {
  for (int i = 0; i < kNumberOfGlobalShortcuts; ++i) {
    SRRecorderControl *sr = (SRRecorderControl *) _recorderControlsHolderView.subviews[i];
    sr.tag = i;
    [sr setKeyCombo:[GlobalShortcuts shortcutForAction:i]];
  }
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo {
  [GlobalShortcuts setShortcut:newKeyCombo forAction:(GlobalShortcutAction)aRecorder.tag];
}

- (IBAction)resetShortcutsToDefaultsPressed:(id)sender {
  // are you sure?
  [GlobalShortcuts resetToDefaults];
  [self updateShortcutControls];
}

@end
