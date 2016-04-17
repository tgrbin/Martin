//
//  LibraryTreeSearch.m
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import "LibraryTreeSearch.h"
#import "LibraryTreeCommon.h"
#import "Tags.h"

NSString * const kLibrarySearchFinishedNotification = @"LibManagerSearchFinished";

@implementation LibraryTreeSearch

static const int kBuffSize = 256; // maximum number of characters in a query
static NSLock *searchLock;
static BOOL appendedCharactersToQuery;
static BOOL poppedCharactersFromQuery;
static NSString *previousSearchQuery;
static NSString *pendingSearchQuery;
static BOOL nowSearching;

static NSMutableArray *searchWords;
static BOOL queryHits[kBuffSize];
static int numberOfHits;

+ (void)initialize {
  searchLock = [NSLock new];
  previousSearchQuery = @"";
}

+ (void)resetSearchState {
  @synchronized(searchLock) {
    previousSearchQuery = @"";
  }
}

+ (void)performSearch:(NSString *)query {

  if (query.length > kBuffSize/2) return;
  
  @synchronized(searchLock) {
    if (nowSearching == YES) {
      pendingSearchQuery = query;
      return;
    } else {
      nowSearching = YES;
    }
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *currentQuery = query;
    
    for (;;) {
      initSearchWords(currentQuery);

      appendedCharactersToQuery = [currentQuery hasPrefix:previousSearchQuery];
      poppedCharactersFromQuery = [previousSearchQuery hasPrefix:currentQuery];

      searchTree(0);
      
      previousSearchQuery = currentQuery;
      
      @synchronized(searchLock) {
        if (pendingSearchQuery) {
          currentQuery = pendingSearchQuery;
          pendingSearchQuery = nil;
        } else {
          currentQuery = nil;
          break;
        }
      }
    }
    
    @synchronized(searchLock) {
      nowSearching = NO;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kLibrarySearchFinishedNotification object:nil];
    });
  });
}

+ (BOOL)currentQueryMatchesString:(NSString *)string {
  BOOL matches = YES;
  
  for (NSString *word in [previousSearchQuery componentsSeparatedByString:@" "]) {
    if (word.length > 0) {
      if ([string rangeOfString:word
                        options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch].location == NSNotFound) {
        matches = NO;
      }
    }
  }
  
  return matches;
}

static void initSearchWords(NSString *query) {
  searchWords = [NSMutableArray new];
  
  for (NSString *word in [query componentsSeparatedByString:@" "]) {
    if (word.length > 0) {
      [searchWords addObject:word];
    }
  }
}

static BOOL checkForMatch(int wordIndex, NSString *str) {
  return [str rangeOfString:searchWords[wordIndex]
                    options:NSDiacriticInsensitiveSearch|NSCaseInsensitiveSearch].location != NSNotFound;
}

static BOOL searchInNode(int wordIndex, const struct LibraryTreeNode& node) {
  if (checkForMatch(wordIndex, node.name)) {
    return YES;
  }
  
  if (node.p_song == -1) {
    return NO;
  }
  
  struct LibrarySong& song = songs[node.p_song];
  for (int i = 0; i < kNumberOfTags; ++i) {
    if (checkForMatch(wordIndex, song.tags[i]) == YES) {
      return YES;
    }
  }

  return NO;
}

static int searchTree(int p_node) {
  struct LibraryTreeNode &node = nodes[p_node];
  
  BOOL wholeNodeMatching = (node.searchState == kSearchStateWholeNodeMatching || node.searchState == kSearchStateWholeNodePropagated);
  
  if (poppedCharactersFromQuery && wholeNodeMatching) return 1;
  if (appendedCharactersToQuery && node.searchState == kSearchStateNotMatching) return 0;
  
  vector<int> modified;
  for (int i = 0; i < searchWords.count; ++i) {
    if (queryHits[i]) continue;
    
    if (searchInNode(i, node)) {
      queryHits[i] = YES;
      ++numberOfHits;
      modified.push_back(i);
    }
  }
  
  if (numberOfHits == searchWords.count) {
    node.searchState = kSearchStateWholeNodeMatching;
  } else {
    node.searchState = kSearchStateNotMatching;
  
    for (auto it = node.children.begin(); it != node.children.end(); ++it) {
      if (wholeNodeMatching) {
        nodes[*it].searchState = kSearchStateWholeNodeMatching;
      }
      if (searchTree(*it)) {
        node.searchState = kSearchStateSomeChildrenMatching;
      }
    }
  }
  
  for (int i = 0; i < modified.size(); ++i) {
    --numberOfHits;
    queryHits[modified[i]] = NO;
  }
  
  return node.searchState > 0? 1: 0;
}

@end
