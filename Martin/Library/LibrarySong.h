//
//  LibrarySong.h
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

struct LibrarySong {
  int lengthInSeconds;
  time_t lastModified;
  int p_treeLeaf;
  char **tags;
};
