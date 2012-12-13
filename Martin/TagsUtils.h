//
//  TagsUtils.h
//  Martin
//
//  Created by Tomislav Grbin on 12/12/12.
//
//

#define kNumberOfTags 5

void tagsInit(char ***tags);
void tagsSet(char **tags, int i, char *val);
NSString *tagsNSStringGet(char **tags, int i);
