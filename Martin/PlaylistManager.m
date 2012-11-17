//
//  PlaylistManager.m
//  Martin
//
//  Created by Tomislav Grbin on 10/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TableSongsDataSource.h"
#import "MartinAppDelegate.h"
#import "PlaylistManager.h"
#import "Playlist.h"
#import "Player.h"

@implementation PlaylistManager

@synthesize playlists, appDelegate;
@synthesize table, addPlaylistButton, deleteButton, shuffleButton;
@synthesize shuffleOn;

- (id)init {
    if( self = [super init] ) {
        playlists = [[NSMutableArray alloc] init];

        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Playlists" ofType:@"plist"];
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        NSDictionary *data = [NSPropertyListSerialization propertyListWithData:plistXML options:NSPropertyListImmutable format:NULL error:nil];
        
        for( NSString *key in data ) {
            NSArray *songs = (NSArray*) [data objectForKey:key];
            Playlist *playlist = [[Playlist alloc] initWithName:key array:songs];
            [playlists addObject:playlist];
        }
    }
    
    return self;
}

- (void)savePlaylists {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Playlists" ofType:@"plist"];
    
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    
    for( Playlist *item in playlists ) {
        [keys addObject:item.name];
        [values addObject:item.songs];
    }
    
    NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:plistDict format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
    
    [plistData writeToFile:plistPath atomically:YES];
}

- (void)choosePlaylist:(NSInteger)index {
    selectedPlaylist = [playlists objectAtIndex:index];
    
    TableSongsDataSource *tableSongsDataSource = (TableSongsDataSource*) appDelegate.songsTableView.dataSource;
    
    tableSongsDataSource.playlist = selectedPlaylist;
    tableSongsDataSource.sortedColumn = nil;
    [appDelegate.songsTableView reloadData];
}

#pragma mark - button pressed

- (IBAction)buttonPressed:(id)sender {
    if( sender == addPlaylistButton ) {
        [playlists addObject:[[Playlist alloc] init]];
        [table reloadData];
        [table selectRowIndexes:[NSIndexSet indexSetWithIndex:[playlists count]-1] byExtendingSelection:NO];
    } else if( sender == deleteButton ) {
        if( [playlists count] > 1 ) { // nemozes izbrisat sve playliste
            if( [playlists objectAtIndex:[table selectedRow]] == nowPlayingPlaylist ) nowPlayingPlaylist = nil;	
            [playlists removeObjectAtIndex:[table selectedRow]];
            [table reloadData];
            [self choosePlaylist:[table selectedRow]];
        }
    } else if( sender == shuffleButton ) {
        shuffleOn = shuffleButton.intValue > 0;
    }
}

#pragma mark - table data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [playlists count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return ((Playlist*)[playlists objectAtIndex:row]).name;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    Playlist *playlist = [playlists objectAtIndex:row];
    playlist.name = (NSString*)object;
}

#pragma mark - table delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self choosePlaylist:[table selectedRow]];
}

#pragma mark - playing songs

- (int) currentSongID {
    if( nowPlayingPlaylist == nil ) nowPlayingPlaylist = selectedPlaylist;
    return [nowPlayingPlaylist currentID];
}

- (int) nextSongID {
    if( nowPlayingPlaylist == nil ) nowPlayingPlaylist = selectedPlaylist;
    return [nowPlayingPlaylist nextSongIDShuffled:shuffleOn];
}

- (int) prevSongID {
    if( nowPlayingPlaylist == nil ) nowPlayingPlaylist = selectedPlaylist;
    return [nowPlayingPlaylist prevSongIDShuffled:shuffleOn];
}

- (void) songDoubleClicked {
    nowPlayingPlaylist = selectedPlaylist;
    [nowPlayingPlaylist setCurrentSong:(int)appDelegate.songsTableView.clickedRow];
    [appDelegate.player play];
}

@end
