//
//  PlaylistTableView.m
//  Martin
//
//  Created by Tomislav Grbin on 4/13/13.
//
//

#import "PlaylistTableView.h"
#import "MartinAppDelegate.h"

@implementation PlaylistTableView

- (BOOL)becomeFirstResponder {
  [[MartinAppDelegate get].playlistTableManager gotFocus];
  return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
  [[MartinAppDelegate get].playlistTableManager lostFocus];
  return [super resignFirstResponder];
}

@end
