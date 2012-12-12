//
//  Tags.h
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import <Foundation/Foundation.h>

@interface Tags : NSObject
+ (Tags *)createTagsFromCTags:(char **)tags;
- (NSString *)tagValueForIndex:(int)i;
@end
