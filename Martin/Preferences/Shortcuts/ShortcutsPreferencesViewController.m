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
#import "MediaKeysManager.h"

@interface ShortcutsPreferencesViewController ()
@property (nonatomic, strong) IBOutlet NSView *recorderControlsHolderView;
@property (nonatomic, assign) BOOL mediaKeysEnabled;
@end

@implementation ShortcutsPreferencesViewController

- (id)init {
  if (self = [super init]) {
    self.title = @"Shortcuts";
    _mediaKeysEnabled = [MediaKeysManager shared].mediaKeysEnabled;
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
  [GlobalShortcuts resetToDefaults];
  [self updateShortcutControls];
}

- (void)setMediaKeysEnabled:(BOOL)mediaKeysEnabled {
  _mediaKeysEnabled = mediaKeysEnabled;
  
  // TODO: grey out the whole section when keys are disabled
  [MediaKeysManager shared].mediaKeysEnabled = mediaKeysEnabled;
}

@end
