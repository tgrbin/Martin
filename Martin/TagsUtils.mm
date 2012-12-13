//
//  TagsUtils.m
//  Martin
//
//  Created by Tomislav Grbin on 12/12/12.
//
//

#import <malloc/malloc.h>
#import "TagsUtils.h"

void tagsInit(char ***tags) {
  *tags = (char **)malloc(kNumberOfTags * sizeof(char*));
  for (int i = 0; i < kNumberOfTags; (*tags)[i++] = 0);
}

void tagsSet(char **tags, int i, char *val) {
  size_t len = strlen(val);
  val[len-1] = 0; // remove newline
  
  if (tags[i] == 0) {
    tags[i] = (char *)malloc(len);
  } else {
    size_t sz = malloc_size(tags[i]);
    if (len+1 > sz) tags[i] = (char *)realloc(tags[i], len+1);
  }
  
  strcpy(tags[i], val);
}

NSString *tagsNSStringGet(char **tags, int i) {
  return [NSString stringWithCString:tags[i] encoding:NSUTF8StringEncoding];
}
