//
//  Tags.h
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import <Foundation/Foundation.h>

@interface Tags : NSObject {
  __unsafe_unretained NSString **tags;
}

+ (int)numberOfTags;
+ (NSString *)tagNameForIndex:(int)i;
+ (int)indexForTagName:(NSString *)name;

- (void)setTag:(NSString *)tag forIndex:(int)i;
- (NSString *)tagForIndex:(int)i;

@end
