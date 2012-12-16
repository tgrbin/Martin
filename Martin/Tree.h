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
  int inode;
  int lengthInSeconds;
  int lastModified;
  int p_treeLeaf;
  char **tags;
};

@interface Tree : NSObject

+ (void)clearTree;
+ (int)addChild:(NSString *)name parent:(int)p_parent song:(int)p_song;

+ (NSString *)nameForNode:(int)p_node;
+ (int)numberOfChildrenForNode:(int)p_node;
+ (int)childAtIndex:(int)i forNode:(int)p_node;
+ (int)parentOfNode:(int)p_node;
+ (BOOL)isLeaf:(int)p_node;

+ (int)newSong;
+ (int)songFromNode:(int)p_node;
+ (int)songByInode:(int)inode;
+ (struct LibrarySong *)songDataForP:(int)p_song;

+ (void)setLibraryPath:(NSString *)p forNode:(int)p_node;
+ (void)addToSongByInodeMap:(int)song inode:(int)inode;

+ (NSString *)fullPathForSong:(int)p_song;
+ (NSString *)fullPathForNode:(int)p_node;

+ (void)performSearch:(NSString *)query;

@end
