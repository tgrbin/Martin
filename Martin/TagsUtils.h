//
//  TagsUtils.h
//  Martin
//
//  Created by Tomislav Grbin on 12/12/12.
//
//

#define kNumberOfTags 5

NSString *tagsNSStringName(int);
int tagsIndexFromNSString(NSString *);

void tagsInit(char ***);
void tagsSet(char **, int, const char *);
NSString *tagsNSStringGet(char **, int);
