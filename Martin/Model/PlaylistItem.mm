//
//  PlaylistItem.m
//  Martin
//
//  Created by Tomislav Grbin on 11/20/12.
//
//

#import "PlaylistItem.h"
#import "LibManager.h"
#import "LibraryTree.h"
#import "LibrarySong.h"
#import "Tags.h"
#import "ID3Reader.h"
#import "ID3ReadOperation.h"
#import "MartinAppDelegate.h"
#import "Stream.h"

#import "NSString+Stream.h"

static NSOperationQueue *operationQueue;

@implementation PlaylistItem {
  Tags *tags;
  ID3ReadOperation *id3ReadOperation;
}

@synthesize inode = _inode;
@synthesize filename = _filename;
@synthesize lengthInSeconds = _lengthInSeconds;

+ (void)initialize {
  operationQueue = [NSOperationQueue new];
  operationQueue.name = @"playlist item id3 read queue";
  [operationQueue addObserver:[MartinAppDelegate get]
                   forKeyPath:@"operationCount"
                      options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                      context:NULL];
}

- (id)initWithLibrarySong:(int)p_song {
  if (self = [super init]) {
    _p_librarySong = p_song;
    _inode = [LibraryTree inodeForSong:p_song];
  }
  return self;
}

- (id)initWithStream:(Stream *)stream {
  if (self = [super init]) {
    _filename = [stream.urlString copy];
    tags = [Stream createTagsFromStream:stream];
    _isURLStream = YES;
    
    _p_librarySong = -1;
    _lengthInSeconds = 0;
  }
  
  return self;
}

- (id)initWithFileStream:(FILE *)f {
  static const int kBuffSize = 1<<16;
  static char buff[kBuffSize];
    
  if (self = [super init]) {
    fgets(buff, kBuffSize, f);
    sscanf(buff, "%lld", &_inode);

    fgets(buff, kBuffSize, f);
    sscanf(buff, "%d", &_lengthInSeconds);

    fgets(buff, kBuffSize, f);
    buff[strlen(buff)-1] = 0;
    _filename = @(buff);

    _isURLStream = [_filename isURL];
    
    _p_librarySong = -1;
    if (_isURLStream == NO && _inode != 0) {
      _p_librarySong = [LibraryTree songByInode:_inode];
    }

    // library songs get tags from the library
    NSMutableArray *tagValues = [NSMutableArray new];
    for (int i = 0; i < kNumberOfTags; ++i) {
      fgets(buff, kBuffSize, f);
      if (_p_librarySong == -1) {
        buff[strlen(buff) - 1] = 0; // remove newline
        [tagValues addObject:@(buff)];
      }
    }
    
    if (_p_librarySong == -1) {
      tags = [Tags createTagsFromArray:tagValues];
    }
  }
  
  return self;
}

- (id)initWithPath:(NSString *)path andInode:(ino_t)inode {
  if (self = [super init]) {
    _p_librarySong = -1;
    _filename = path;
    _inode = inode;
    
    _p_librarySong = [LibraryTree songByInode:inode];
    if (_p_librarySong == -1) {
      id3ReadOperation = [[ID3ReadOperation alloc] initWithPlaylistItem:self];
      [operationQueue addOperation:id3ReadOperation];
    }
  }
  
  return self;
}

- (void)dealloc {
  [self cancelID3Read];
}

- (void)cancelID3Read {
  if (id3ReadOperation) {
    [id3ReadOperation cancel];
    id3ReadOperation = nil;
  }
}

- (void)createTagsFromArray:(NSArray *)array {
  tags = [Tags createTagsFromArray:array];
}

- (NSString *)filename {
  [self checkLibrarySong];
  if (_p_librarySong != -1) return [LibraryTree pathForSong:_p_librarySong];
  return _filename;
}

- (int)lengthInSeconds {
  [self checkLibrarySong];
  if (_p_librarySong != -1) return [LibraryTree songDataForP:_p_librarySong]->lengthInSeconds;
  return _lengthInSeconds;
}

- (NSString *)tagValueForIndex:(TagIndex)i {
  [self checkLibrarySong];
  if (_p_librarySong != -1) {
    return [LibraryTree songDataForP:_p_librarySong]->tags[i];
  } else {
    NSString *value = [tags tagValueForIndex:i];
    
    if (_isURLStream && i == kTagIndexTitle) {
      Stream *stream = [[MartinAppDelegate get].streamsController streamWithURLString:_filename];
      
      if (stream != nil) {
        return stream.name;
      }
    }
    
    return value;
  }
}

- (void)outputToFileStream:(FILE *)f {
  [self checkLibrarySong];
  
  fprintf(f, "%lld\n", _inode);
  
  if (_p_librarySong == -1) {
    fprintf(f, "%d\n", _lengthInSeconds);
    fprintf(f, "%s\n", _filename == nil? "": [_filename UTF8String]);
    for (int i = 0; i < kNumberOfTags; ++i) fprintf(f, "%s\n", [[self tagValueForIndex:(TagIndex)i] UTF8String]);
  } else {
    struct LibrarySong *song = [LibraryTree songDataForP:_p_librarySong];
    fprintf(f, "%d\n", song->lengthInSeconds);
    fprintf(f, "%s\n", [[LibraryTree pathForSong:_p_librarySong] UTF8String]);
    for (int i = 0; i < kNumberOfTags; ++i) fprintf(f, "%s\n", [song->tags[i] UTF8String]);
  }
}

- (void)checkLibrarySong {
  if (_p_librarySong == -1) return;
  if ([LibraryTree inodeForSong:_p_librarySong] != _inode) _p_librarySong = [LibraryTree songByInode:_inode];
}

@end
