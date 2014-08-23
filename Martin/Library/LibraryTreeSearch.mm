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

static int numberOfWords;
static char searchWords[kBuffSize][kBuffSize];
static size_t wordLen[kBuffSize];
static int kmpLookup[kBuffSize][kBuffSize];
static BOOL queryHits[kBuffSize];
static int numberOfHits;

+ (void)resetSearchState {
  @synchronized(searchLock) {
    [previousSearchQuery release];
    previousSearchQuery = @"";
  }
}

+ (void)performSearch:(NSString *)query {
  if (searchLock == nil) {
    searchLock = [NSLock new];
    previousSearchQuery = @"";
  }

  if (query.length > kBuffSize/2) return;
  
  @synchronized(searchLock) {
    if (nowSearching == YES) {
      [pendingSearchQuery release];
      pendingSearchQuery = [query retain];
      return;
    }
    nowSearching = YES;
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSString *currentQuery = [query copy];
    
    for (;;) {
      initKMPStructures(currentQuery);

      appendedCharactersToQuery = [currentQuery hasPrefix:previousSearchQuery];
      poppedCharactersFromQuery = [previousSearchQuery hasPrefix:currentQuery];

      searchTree(0);
      
      [previousSearchQuery release];
      previousSearchQuery = [currentQuery copy];
      
      @synchronized(searchLock) {
        if (pendingSearchQuery) {
          [currentQuery release];
          currentQuery = [pendingSearchQuery copy];
          [pendingSearchQuery release];
          pendingSearchQuery = nil;
        } else {
          [currentQuery release];
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

static void initKMPStructures(NSString *query) {
  numberOfWords = 0;
  
  for (NSString *word in [query componentsSeparatedByString:@" "]) {
    if (word.length == 0) continue;
    
    char *w = searchWords[numberOfWords];
    int *t = kmpLookup[numberOfWords];
    
    [word getCString:w maxLength:kBuffSize encoding:NSUTF8StringEncoding];
    
    size_t len = strlen(w);
    wordLen[numberOfWords++] = len;
    
    int i = 0;
    int j = t[0] = -1;
    while (i < len) {
      while (j > -1 && toupper(w[i]) != toupper(w[j])) j = t[j];
      ++i;
      ++j;
      if (toupper(w[i]) == toupper(w[j])) t[i] = t[j];
      else t[i] = j;
    }
  }
}

static BOOL kmpSearch(int wordIndex, const char *str) {
  char *w = searchWords[wordIndex];
  int *t = kmpLookup[wordIndex];
  size_t len = wordLen[wordIndex];
  
  size_t strLen = strlen(str);
  int i = 0, j = 0;
  while (j < strLen) {
    while (i > -1 && toupper(w[i]) != toupper(str[j])) i = t[i];
    ++i;
    ++j;
    if (i >= len) return YES;
  }
  return NO;
}

static BOOL searchInNode(int wordIndex, const struct LibraryTreeNode &node) {
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
