//
//  LibraryTreeSearch.m
//  Martin
//
//  Created by Tomislav Grbin on 23/08/14.
//
//

#import "LibraryTreeSearch.h"
#import "LibraryTreeCommon.h"
#import "TagsUtils.h"

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
static int kmpLookup[kBuffSize][kBuffSize];
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
      initKMPStructures(currentQuery);

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
  
  string = [string lowercaseString];
  
  for (NSString *word in [previousSearchQuery componentsSeparatedByString:@" "]) {
    if (word.length > 0) {
      if ([string rangeOfString:word options:NSCaseInsensitiveSearch].location == NSNotFound) {
        matches = NO;
      }
    }
  }
  
  return matches;
}

static void initKMPStructures(NSString *query) {
  searchWords = [NSMutableArray new];
  
  for (NSString *word in [[query lowercaseString] componentsSeparatedByString:@" "]) {
    if (word.length == 0) continue;
    
    int *t = kmpLookup[searchWords.count];
    [searchWords addObject:word];
    
    int i = 0;
    int j = t[0] = -1;
    while (i < word.length) {
      while (j > -1 && [word characterAtIndex:i] != [word characterAtIndex:j]) j = t[j];
      ++i;
      ++j;
      if ([word characterAtIndex:i] == [word characterAtIndex:j]) t[i] = t[j];
      else t[i] = j;
    }
  }
}

static BOOL kmpSearch(int wordIndex, NSString *str) {
  NSString *word = searchWords[wordIndex];
  NSString *lowercaseStr = [str lowercaseString];
  int *t = kmpLookup[wordIndex];
  size_t len = word.length;
  
  NSUInteger strLen = str.length;
  int i = 0, j = 0;
  while (j < strLen) {
    while (i > -1 && [word characterAtIndex:i] != [lowercaseStr characterAtIndex:j]) i = t[i];
    ++i;
    ++j;
    if (i >= len) return YES;
  }
  return NO;
}

static BOOL searchInNode(int wordIndex, const struct LibraryTreeNode& node) {
  if (kmpSearch(wordIndex, node.name)) return YES;
  
  if (node.p_song == -1) return NO;
  
  struct LibrarySong &song = songs[node.p_song];
  for (int i = 0; i < kNumberOfTags; ++i) {
    if (kmpSearch(wordIndex, song.tags[i]) == YES) return YES;
  }

  return NO;
}

static int searchTree(int p_node) {
  struct LibraryTreeNode &node = nodes[p_node];
  
  BOOL wholeNodeMatching = (node.searchState == kSearchStateWholeNodeMatching || node.searchState == kSearchStateWholeNodePropagated);
  
  if (poppedCharactersFromQuery && wholeNodeMatching) return 1;
  if (appendedCharactersToQuery && node.searchState == kSearchStateNotMatching) return 0;
  
  vector<int> modified;
  for (int i = 0; i < numberOfWords; ++i) {
    if (queryHits[i]) continue;
    
    if (searchInNode(i, node)) {
      queryHits[i] = YES;
      ++numberOfHits;
      modified.push_back(i);
    }
  }
  
  if (numberOfHits == numberOfWords) {
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
