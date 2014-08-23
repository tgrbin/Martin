//
//  PlaylistPublic.h
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import "Playlist.h"

#import <vector>
#import <map>

using namespace std;

@interface Playlist () {
@protected
  vector<PlaylistItem *> playlistItems;
  
  // these variables hold indexes within playlistItems vector
  vector<int> playlist;
  vector<int> playedItems;
  
  // variables used only by queue
  BOOL isQueue;
  // used to track where to continue playing after queue is exhausted
  // every item playlistItems has corresponding element here pointing to originating playlist
  vector<Playlist *> itemOrigin;
  // used when storing queue state to playlists file
  // this is used only when exiting application and saving playlists to a file,
  // so it's safe to initialize data structure only once
  BOOL playlistItemsIndexInitialized;
  map<PlaylistItem *, int> playlistItemsIndex;
  
  // stored indexes for keeping selected items between sorts
  vector<BOOL> storedIndexes;
}

- (int)indexOfPlaylistItem:(PlaylistItem *)playlistItem;

@end
