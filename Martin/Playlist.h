//
//  Playlist.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Playlist : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableArray *shuffledSongs;
@property (nonatomic, retain) NSMutableArray *songs;
@property (nonatomic, retain) NSMutableArray *tmpAddSongs;
@property (nonatomic, retain) NSMutableSet *songsSet;
@property (nonatomic, assign) int currentID;

- (id)initWithName:(NSString*) n array:(NSArray*) s;
- (void)addSongs:(NSArray*) treeNodes atPos:(NSInteger)pos;
- (void)removeSongsAtIndexes:(NSIndexSet *)indexes;
- (int)reorderSongs:(NSArray*) rows atPos:(NSInteger)pos;
- (void)insertArray:(NSArray*) arr atPos:(NSInteger)pos;

- (int)nextSongIDShuffled:(BOOL)shuffled;
- (int)prevSongIDShuffled:(BOOL)shuffled;
- (void)setCurrentSong:(int)index;

@end
