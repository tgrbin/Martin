//
//  TreeStateManager.m
//  Martin
//
//  Created by Tomislav Grbin on 12/28/12.
//
//

#import "TreeStateManager.h"
#import "DefaultsManager.h"

@implementation TreeStateManager

+ (void)saveStateForOutlineView:(NSOutlineView *)outlineView {
  NSMutableArray *arr = [NSMutableArray array];
  NSInteger n = outlineView.numberOfRows;
  for (int i = 0; i < n; ++i) {
    NSNumber *item = [outlineView itemAtRow:i];
    if ([outlineView isItemExpanded:item]) [arr addObject:item];
  }

  [DefaultsManager setObject:arr forKey:kDefaultsKeyTreeState];
}

+ (void)restoreStateToOutlineView:(NSOutlineView *)outlineView {
  NSArray *arr = [DefaultsManager objectForKey:kDefaultsKeyTreeState];

  [outlineView collapseItem:nil collapseChildren:YES];
  for (id item in arr) [outlineView expandItem:@([item intValue])];
}

@end
