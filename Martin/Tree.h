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
  time_t lastModified;
  int p_treeLeaf;
  char **tags;
};

struct TreeNode;

@interface Tree : NSObject

+ (void)clearTree;

+ (int)numberOfChildrenForNode:(int)p_node;
+ (int)childAtIndex:(int)i forNode:(int)p_node;
+ (int)parentOfNode:(int)p_node;
+ (BOOL)isLeaf:(int)p_node;
+ (NSString *)nameForNode:(int)p_node;

+ (int)songFromNode:(int)p_node;

+ (int)songByInode:(ino_t)inode;
+ (int)nodeByInode:(ino_t)inode;

+ (void)addToNodeByInodeMap:(int)node;

+ (NSString *)fullPathForSong:(int)p_song;

+ (void)performSearch:(NSString *)query;

// won't return paths that are subpaths of another path
+ (NSArray *)pathsForNodes:(NSArray *)nodes;

+ (int)addChild:(char *)name parent:(int)p_parent;
+ (struct LibrarySong *)newSong;
+ (struct LibrarySong *)songDataForP:(int)p_song;
+ (struct TreeNode *)treeNodeDataForP:(int)p_node;

@end
