//
//  Tree.h
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import <Foundation/Foundation.h>

#define kLibrarySearchFinishedNotification @"LibManagerSearchFinished"

struct LibrarySong {
  int lengthInSeconds;
  int lastModified;
  int p_treeLeaf;
  char **tags;
};

@interface Tree : NSObject

+ (void)clearTree;
+ (int)addChild:(char *)name parent:(int)p_parent song:(int)p_song;

+ (int)numberOfChildrenForNode:(int)p_node;
+ (int)childAtIndex:(int)i forNode:(int)p_node;
+ (int)parentOfNode:(int)p_node;
+ (BOOL)isLeaf:(int)p_node;
+ (NSString *)nameForNode:(int)p_node;

+ (int)newSong;
+ (int)songFromNode:(int)p_node;
+ (int)songByInode:(int)inode;
+ (void)addToSongByInodeMap:(int)song inode:(int)inode;
+ (struct LibrarySong *)songDataForP:(int)p_song;

+ (void)setLibraryPath:(NSString *)p forNode:(int)p_node;

+ (NSString *)fullPathForSong:(int)p_song;

+ (void)performSearch:(NSString *)query;

// won't return paths that are subpaths of another path
+ (NSArray *)pathsForNodes:(NSArray *)nodes;

@end
