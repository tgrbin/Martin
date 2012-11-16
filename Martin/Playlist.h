//
//  Playlist.h
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Playlist : NSObject {
  BOOL currentIDRemoved;
  int suggestedID; // ako se izbrise pjesma koja trenutno svira, koji ID da svira sljedeci
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray *shuffledSongs;
@property (nonatomic, strong) NSMutableArray *songs;
@property (nonatomic, strong) NSMutableArray *tmpAddSongs;
@property (nonatomic, strong) NSMutableSet *songsSet;
@property (nonatomic, assign) int currentID;

- (id)initWithName:(NSString *)n array:(NSArray *)s;
- (void)addSongs:(NSArray *)treeNodes atPos:(NSInteger)pos;
- (void)removeSongsAtIndexes:(NSIndexSet *)indexes;
- (int)reorderSongs:(NSArray *)rows atPos:(NSInteger)pos;
- (void)insertArray:(NSArray *)arr atPos:(NSInteger)pos;

- (void)sortBy:(NSString *)str;
- (void)reverse;

- (int)nextSongIDShuffled:(BOOL)shuffled;
- (int)prevSongIDShuffled:(BOOL)shuffled;
- (void)setCurrentSong:(int)index;

@end
