//
//  PreferencesViewController.m
//  Martin
//
//  Created by Tomislav Grbin on 3/30/13.
//
//

#import "PreferencesViewController.h"

@implementation PreferencesViewController

- (int)height {
  return self.view.frame.size.height;
}

- (id)init {
  return self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
}

@end
