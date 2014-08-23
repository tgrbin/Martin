//
//  LibraryTreeSearch.h
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import <Foundation/Foundation.h>

extern NSString * const kLibrarySearchFinishedNotification;

@interface LibraryTreeSearch : NSObject

+ (void)performSearch:(NSString *)query;
+ (void)resetSearchState;

+ (BOOL)currentQueryMatchesString:(NSString *)string;

@end
