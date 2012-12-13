//
//  Tags.h
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import <Foundation/Foundation.h>
#import "TagsUtils.h"

@interface Tags : NSObject
+ (NSString *)tagNameForIndex:(int) i;
+ (int)indexFromTagName:(NSString *)str;

+ (Tags *)createTagsFromCTags:(char **)tags;
- (NSString *)tagValueForIndex:(int)i;
@end
