//
//  Playlist.m
//  Martin
//
//  Created by Tomislav Grbin on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <stdlib.h>
#import "Playlist.h"
#import "TreeLeaf.h"
#import "TreeNode.h"
#import "Song.h"
#import "LibManager.h"

@implementation Playlist

void find_songs( TreeNode *t, Playlist *p );

@synthesize songs, songsSet, tmpAddSongs, name;
@synthesize shuffledSongs, currentID;

#pragma mark - init

- (id)initWithName:(NSString *)n array:(NSArray *)s {
    if( self = [super init] ) {
        name = [n retain];
        tmpAddSongs = [[NSMutableArray alloc] init];
        songs = [[NSMutableArray alloc] initWithArray:s];
        songsSet = [[NSMutableSet alloc] initWithArray:s];

        if( [s count] ) currentID = [[songs objectAtIndex:0] intValue];
        else currentID = -1;
        
        shuffledSongs = [[NSMutableArray alloc] initWithArray:songs];
        for( int i = 0; i < [shuffledSongs count]; ++i ) {
            int j = i + arc4random() % ((int)[shuffledSongs count]-i);
            [shuffledSongs exchangeObjectAtIndex:i withObjectAtIndex:j];
        }
    }
    return self;
}

- (id)init {
    return [self initWithName:@"new playlist" array:[NSArray array]];
}

#pragma mark - manage playlist

- (void)addSongs:(NSArray *)treeNodes atPos:(NSInteger)pos {
    [tmpAddSongs removeAllObjects];
    
    for( TreeNode *t in treeNodes ) find_songs( t, self );
    
    [self insertArray:tmpAddSongs atPos:pos];
    
    int shuffledPosition = (int)[shuffledSongs indexOfObject:[NSNumber numberWithInt:currentID]];
    [shuffledSongs addObjectsFromArray:tmpAddSongs];
    
    for( int i = shuffledPosition+1; i < [shuffledSongs count]; ++i ) {
        int j = i + arc4random() % ((int)[shuffledSongs count]-i);
        [shuffledSongs exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    
    if( currentID == -1 ) currentID = [[songs objectAtIndex:0] intValue];
}

- (void)insertArray:(NSArray*)arr atPos:(NSInteger)pos {
    int tmpLen = (int)[arr count];
    int len = (int)[songs count];
    
    for( int i = 0; i < tmpLen; ++i ) [songs addObject:[NSNumber numberWithInt:0]];
    
    for( int i = len+tmpLen-1; i >= pos+tmpLen; --i )
        [songs replaceObjectAtIndex:i withObject:[songs objectAtIndex:i-tmpLen]];
    
    for( int i = (int)pos; i < pos+tmpLen; ++i )
        [songs replaceObjectAtIndex:i withObject:[arr objectAtIndex:i-pos]];
}

- (int)reorderSongs:(NSArray*)rows atPos:(NSInteger)pos {
    NSMutableArray *tmpArr = [[NSMutableArray alloc] init];
    
    int len = (int)[songs count];
    int rowsLen = (int)[rows count];
    int j = 0, k = 0, posDelta = 0;
    
    for( int i = 0; i < len; ++i ) {
        int nextRow = (j<rowsLen)? [[rows objectAtIndex:j] intValue]: len;
        if( i == nextRow ) {
            if( i < pos ) ++posDelta;
            [tmpArr addObject:[songs objectAtIndex:nextRow]];
            ++j;
        } else {
            if( i != k ) [songs replaceObjectAtIndex:k withObject:[songs objectAtIndex:i]];
            ++k;
        }
    }
    
    for(; k < len; ++k ) [songs removeLastObject];
    pos -= posDelta;
    [self insertArray:tmpArr atPos:pos];
    [tmpArr release];
    return (int)pos;
}

void find_songs( TreeNode *node, Playlist *p ) {
    if( [node isKindOfClass:[TreeLeaf class]] ) {
        NSNumber *songID = [NSNumber numberWithInt:((TreeLeaf*)node).song.ID];
        
        if( ![p.songsSet containsObject:songID] ) {
            [p.songsSet addObject:songID];
            [p.tmpAddSongs addObject:songID];
        }
    } else {
        int n = [node nChildren];
        for( int i = 0; i < n; ++i )
            find_songs( [node getChild:i], p );
    }
}

- (void)sortBy:(NSString *)str {
    [songs sortUsingComparator:^NSComparisonResult(id id1, id id2) {
        Song *s1 = [LibManager songByID:[id1 intValue]];
        Song *s2 = [LibManager songByID:[id2 intValue]];
        NSString *val1 = [s1 valueForKey:str];
        NSString *val2 = [s2 valueForKey:str];
        
        if( [str isEqualToString:@"trackNumber"] ) return [val1 intValue] > [val2 intValue];
        return [val1 caseInsensitiveCompare:val2];
    }];
}

- (void)reverse {
    int n = (int) [songs count];
    for( int i = 0; i+i < n; ++i )
        [songs exchangeObjectAtIndex:i withObjectAtIndex:n-i-1];
}

- (void)removeSongsAtIndexes:(NSIndexSet *)indexes {
    currentIDRemoved = NO;
    
    NSUInteger curr = [indexes firstIndex];
    int pos;
    while( curr != NSNotFound ) {
        NSNumber *song = [songs objectAtIndex:curr];
        if( song.intValue == currentID || (currentIDRemoved == YES && song.intValue == suggestedID) ) {
            currentIDRemoved = YES;
            suggestedID = song.intValue;
            pos = (int) curr;
        }
        [songsSet removeObject:song];
        curr = [indexes indexGreaterThanIndex:curr];
    }

    if( currentIDRemoved ) {
        for(;;) {
            int next = (int) [indexes indexGreaterThanIndex:pos];
            if( next == NSNotFound ) {
                if( pos == [songs count]-1 ) pos = -1;
            } else {
                if( next == pos+1 ) { ++pos; continue; }
            }
            ++pos;
            break;
        }
        suggestedID = [[songs objectAtIndex:pos] intValue];
    }
    
    [songs removeObjectsAtIndexes:indexes];
    
    NSMutableIndexSet *shuffledIndexes = [NSMutableIndexSet indexSet];
    for( int i = 0; i < [shuffledSongs count]; ++i ) {
        if( ![songsSet containsObject:[shuffledSongs objectAtIndex:i]] ) [shuffledIndexes addIndex:i];
    }
    [shuffledSongs removeObjectsAtIndexes:shuffledIndexes];
}

#pragma mark - playing songs

- (int)nextSongIDShuffled:(BOOL)shuffled {    
    if( currentID == -1 ) return -1;
    
    NSArray *arr = shuffled? shuffledSongs: songs;
    int pos;
    
    if( currentIDRemoved == YES ) {
        currentIDRemoved = NO;
        pos = (int) [arr indexOfObject:[NSNumber numberWithInt:suggestedID]]-1;
    } else {
        pos = (int) [arr indexOfObject:[NSNumber numberWithInt:currentID]];
    }
    
    return currentID = [(NSNumber*)[arr objectAtIndex:(pos+1)%[arr count]] intValue];
}

- (int)prevSongIDShuffled:(BOOL)shuffled {
    if( currentID == -1 ) return -1;
    
    NSArray *arr = shuffled? shuffledSongs: songs;
    int pos;
    
    if( currentIDRemoved == YES ) {
        currentIDRemoved = NO;
        pos = (int) [arr indexOfObject:[NSNumber numberWithInt:suggestedID]];
    } else {
        pos = (int) [arr indexOfObject:[NSNumber numberWithInt:currentID]];
    }
    
    return currentID = [(NSNumber*)[arr objectAtIndex:(pos-1)%[arr count]] intValue];
}

- (void)setCurrentSong:(int)index {
    currentID = (int) [[songs objectAtIndex:index] intValue];
}

#pragma mark - dealloc

- (void)dealloc {
    [name release];
    [songs release];
    [tmpAddSongs release];
    [songsSet release];
    [shuffledSongs release];
    [super dealloc];
}

@end
