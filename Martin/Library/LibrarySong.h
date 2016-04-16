//
//  LibrarySong.h
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import <Foundation/Foundation.h>
#import "TagsUtils.h"

struct LibrarySong {
  int lengthInSeconds;
  time_t lastModified;
  int p_treeLeaf;
  NSString* tags[kNumberOfTags];
};
