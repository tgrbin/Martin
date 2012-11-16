//
//  LibManager.m
//  Martin
//
//  Created by Tomislav Grbin on 9/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LibManager.h"
#import "TreeNode.h"
#import "TreeLeaf.h"
#import "Song.h"

#define MAX_CHILDREN 1000
#define MAX_LIB 25000

@implementation LibManager

static TreeNode *root = nil;

static NSString *queries[MAX_CHILDREN];
static BOOL queryHit[MAX_CHILDREN];
static int nQueries, nHit;
static Song *songs[MAX_LIB];

+ (TreeNode *)getRoot {
  if (root == nil) [self loadLibrary];
  return root;
}

+ (Song *)songByID:(int) ID {
  return songs[ID];
}

+ (void)loadLibrary {
  NSString *userMusicDir = [NSSearchPathForDirectoriesInDomains(NSMusicDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString *libPath = [[NSBundle mainBundle] pathForResource:@"martin" ofType:@"lib"];
  NSString *file = [[NSString alloc] initWithContentsOfFile:libPath encoding:NSUTF8StringEncoding error:nil];
  NSArray *lines = [file componentsSeparatedByString:@"\n"];
  NSEnumerator *enumerator = [lines objectEnumerator];
  
  NSMutableArray *path = [NSMutableArray new];
  
  root = [[TreeNode alloc] initWithName:@"root"];
  root.searchState = 2;
  
  NSMutableArray *treePath = [[NSMutableArray alloc] initWithObjects:root, nil];
  
  for (NSString *line; line = [enumerator nextObject];) {
    if ([line length] == 0) break;
    
    NSString *first = [line substringToIndex:1];
    
    if ([first isEqualToString:@"+"]) {
      NSString *folderName = [line substringFromIndex:2];
      TreeNode *new = [[TreeNode alloc] initWithName:folderName];
      TreeNode *curr = [treePath lastObject];

      [path addObject:folderName];
      [treePath addObject:new];
      [curr addChild:new];
    }
    
    if ([first isEqualToString:@"-"]) {
      [path removeLastObject];
      [treePath removeLastObject];
    }
    
    if ([first isEqualToString:@"{"]) {
      Song *mp3 = [Song new];
      mp3.ID = [[enumerator nextObject] intValue];
      
      songs[mp3.ID] = mp3;
      
      NSString *fileName = [enumerator nextObject];
      TreeLeaf *leaf = [[TreeLeaf alloc] initWithName:[fileName stringByDeletingPathExtension]];
      
      mp3.fullPath = [NSString stringWithFormat:@"%@/%@/%@", userMusicDir, [path componentsJoinedByString:@"/"], fileName];
      mp3.trackNumber = [enumerator nextObject];
      mp3.artist = [enumerator nextObject];
      mp3.album = [enumerator nextObject];
      mp3.title = [enumerator nextObject];
      [enumerator nextObject]; // preskoci }
      
      leaf.song = mp3;
      
      [(TreeNode*)[treePath lastObject] addChild:leaf];
    }
  }
}

#pragma mark - search

+ (void)search:(NSString*) query {
  nQueries = 0;
  for (NSString *q in [query componentsSeparatedByString:@" "]) {
    NSString *s = [q stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([s isEqualToString:@""]) continue;
    
    queries[nQueries] = s;
    queryHit[nQueries++] = NO;
  }
  
  nHit = 0;
  traverse(root);
}

static int traverse(TreeNode *node) {
  NSMutableArray *modified = [NSMutableArray new];
  
  for (int i = 0; i < nQueries; ++i) {
    if (queryHit[i] == YES) continue;
    if ([[node name] rangeOfString:queries[i] options:NSCaseInsensitiveSearch].location == NSNotFound) continue;
    
    queryHit[i] = YES;
    ++nHit;
    [modified addObject:[NSNumber numberWithInt:i]];
  }
  
  node.searchState = 0;
  
  if (nHit == nQueries) {
    node.searchState = 2;
  } else {
    for (TreeNode *c in node.children) {
      if(traverse(c)) node.searchState = 1;
    }
  }
  
  for (NSNumber *i in modified) {
    --nHit;
    queryHit[[i intValue]] = NO;
  }
  
  return node.searchState;
}

@end
