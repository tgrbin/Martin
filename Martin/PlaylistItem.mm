//
//  PlaylistItem.m
//  Martin
//
//  Created by Tomislav Grbin on 11/20/12.
//
//

#import "PlaylistItem.h"
#import "LibManager.h"
#import "Tree.h"
#import "Tags.h"
#import "ID3Reader.h"

@implementation PlaylistItem {
  Tags *tags;
}

@synthesize inode = _inode;
@synthesize filename = _filename;
@synthesize lengthInSeconds = _lengthInSeconds;

- (id)initWithLibrarySong:(int)p_song {
  if (self = [super init]) {
    _p_librarySong = p_song;
    _inode = [Tree inodeForSong:p_song];
  }
  return self;
}

- (id)initWithFileStream:(FILE *)f {
  static const int kBuffSize = 1<<16;
  static char buff[kBuffSize];
  static char **ctags;
  if (ctags == NULL) tagsInit(&ctags);
  
  if (self = [super init]) {
    fgets(buff, kBuffSize, f);
    sscanf(buff, "%lld", &_inode);

    fgets(buff, kBuffSize, f);
    sscanf(buff, "%d", &_lengthInSeconds);

    fgets(buff, kBuffSize, f);
    buff[strlen(buff)-1] = 0;
    _filename = @(buff);

    _p_librarySong = _inode? [Tree songByInode:_inode]: -1;

    for (int i = 0; i < kNumberOfTags; ++i) {
      fgets(buff, kBuffSize, f);
      if (_p_librarySong == -1) tagsSet(ctags, i, buff);
    }
    
    if (_p_librarySong == -1) tags = [Tags createTagsFromCTags:ctags];
  }
  
  return self;
}

- (id)initWithPath:(NSString *)path andInode:(ino_t)inode {
  if (self = [super init]) {
    _p_librarySong = -1;
    _filename = path;
    _inode = inode;
    
    _p_librarySong = [Tree songByInode:inode];
    if (_p_librarySong == -1) {
      ID3Reader *id3 = [[ID3Reader alloc] initWithFile:path];
      if (id3 != nil) {
        _lengthInSeconds = id3.lengthInSeconds;
        NSMutableArray *tagsArray = [NSMutableArray new];
        for (int i = 0; i < kNumberOfTags; ++i) {
          NSString *val = [id3 tag:[Tags tagNameForIndex:(TagIndex)i]];
          [tagsArray addObject:val == nil? @"": val];
        }
        tags = [Tags createTagsFromArray:tagsArray];
      }
    }
  }
  
  return self;
}

- (NSString *)filename {
  [self checkLibrarySong];
  if (_p_librarySong != -1) return [Tree pathForSong:_p_librarySong];
  return _filename;
}

- (int)lengthInSeconds {
  [self checkLibrarySong];
  if (_p_librarySong != -1) return [Tree songDataForP:_p_librarySong]->lengthInSeconds;
  return _lengthInSeconds;
}

- (NSString *)tagValueForIndex:(TagIndex)i {
  [self checkLibrarySong];
  if (_p_librarySong != -1) {
    char **t = [Tree songDataForP:_p_librarySong]->tags;
    return @(t[i]);
  } else {
    return [tags tagValueForIndex:i];
  }
}

- (NSString *)prettyName {
  NSString *artist = [self tagValueForIndex:kTagIndexArtist];
  NSString *album = [self tagValueForIndex:kTagIndexAlbum];
  NSString *title = [self tagValueForIndex:kTagIndexTitle];
  
  if (title.length == 0) {
    NSArray *arr = [self.filename pathComponents];
    return [NSString stringWithFormat:@"%@/%@", arr[arr.count-2], arr.lastObject];
  } else {
    return [NSString stringWithFormat:@"%@ - %@ - %@", artist, album, title];
  }
}

- (void)outputToFileStream:(FILE *)f {
  [self checkLibrarySong];
  
  fprintf(f, "{\n");
  fprintf(f, "%lld\n", _inode);
  
  if (_p_librarySong == -1) {
    fprintf(f, "%d\n", _lengthInSeconds);
    fprintf(f, "%s\n", _filename == nil? "": [_filename UTF8String]);
    for (int i = 0; i < kNumberOfTags; ++i) fprintf(f, "%s\n", [[tags tagValueForIndex:(TagIndex)i] UTF8String]);
  } else {
    struct LibrarySong *song = [Tree songDataForP:_p_librarySong];
    fprintf(f, "%d\n", song->lengthInSeconds);
    fprintf(f, "%s\n", [Tree cStringPathForSong:_p_librarySong]);
    for (int i = 0; i < kNumberOfTags; ++i) fprintf(f, "%s\n", song->tags[i]);
  }
  
  fprintf(f, "}\n");
}

- (void)checkLibrarySong {
  if (_p_librarySong == -1) return;
  if ([Tree inodeForSong:_p_librarySong] != _inode) _p_librarySong = [Tree songByInode:_inode];
}

@end
