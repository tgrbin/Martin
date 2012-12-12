//
//  TagsUtils.m
//  Martin
//
//  Created by Tomislav Grbin on 12/12/12.
//
//

#import <malloc/malloc.h>
#import "TagsUtils.h"

static const char *tagNames[] = { "track number", "artist", "album", "title", "genre" };

NSString *tagsNSStringName(int i) {
  return [NSString stringWithCString:tagNames[i] encoding:NSUTF8StringEncoding];
}

int tagsIndexFromNSString(NSString *name) {
  static NSMutableDictionary *dict = nil;
  if (dict == nil) {
    dict = [NSMutableDictionary new];
    for (int i = 0; i < kNumberOfTags; ++i) {
      dict[tagsNSStringName(i)] = @(i);
    }
  }
  return [dict[name] intValue];
}

void tagsInit(char ***tags) {
  *tags = (char **)malloc(kNumberOfTags * sizeof(char*));
  for (int i = 0; i < kNumberOfTags; (*tags)[i++] = 0);
}

void tagsSet(char **tags, int i, const char *val) {
  size_t len = strlen(val);
  size_t sz = malloc_size(tags[i]);
  if (tags[i] == 0) tags[i] = (char *)malloc(len+1);
  if (len+1 > sz) tags[i] = (char *)realloc(tags[i], len+1);
  strcpy(tags[i], val);
}

NSString *tagsNSStringGet(char **tags, int i) {
  return [NSString stringWithCString:tags[i] encoding:NSUTF8StringEncoding];
}
