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

struct TreeNode;

@interface Tree : NSObject

+ (void)clearTree;

+ (int)numberOfChildrenForNode:(int)p_node;
+ (int)childAtIndex:(int)i forNode:(int)p_node;
+ (int)parentOfNode:(int)p_node;
+ (BOOL)isLeaf:(int)p_node;
+ (NSString *)nameForNode:(int)p_node;

+ (int)songFromNode:(int)p_node;

+ (int)songByInode:(int)inode;
+ (int)nodeByInode:(int)inode;

+ (void)addToNodeByInodeMap:(int)node;

+ (NSString *)fullPathForSong:(int)p_song;

+ (void)performSearch:(NSString *)query;

// won't return paths that are subpaths of another path
+ (NSArray *)pathsForNodes:(NSArray *)nodes;

+ (int)addChild:(char *)name parent:(int)p_parent;
+ (struct LibrarySong *)newSong;
+ (struct TreeNode *)treeNodeDataForP:(int)p_node;

@end
