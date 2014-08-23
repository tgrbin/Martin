//
//  Tree.h
//  Martin
//
//  Created by Tomislav Grbin on 12/2/12.
//
//

#import <Foundation/Foundation.h>

struct LibraryTreeNode;

@interface LibraryTree : NSObject

+ (void)clearTree;

+ (int)numberOfChildrenForNode:(int)p_node;
+ (int)childAtIndex:(int)i forNode:(int)p_node;
+ (int)parentOfNode:(int)p_node;
+ (BOOL)isLeaf:(int)p_node;
+ (NSString *)nameForNode:(int)p_node;

+ (int)songFromNode:(int)p_node;
+ (ino_t)inodeForSong:(int)p_song;

+ (int)songByInode:(ino_t)inode;
+ (int)nodeByInode:(ino_t)inode;

+ (void)addToNodeByInodeMap:(int)node;

+ (char *)cStringPathForSong:(int)p_song;
+ (NSString *)pathForSong:(int)p_song;

// won't return paths that are subpaths of another path
+ (NSArray *)pathsForNodes:(NSArray *)nodes;

+ (int)addChild:(char *)name parent:(int)p_parent;
+ (void)setName:(char *)name forNode:(int)p_node;
+ (int)newSong;
+ (struct LibrarySong *)songDataForP:(int)p_song;
+ (struct LibraryTreeNode *)treeNodeDataForP:(int)p_node;

@end
