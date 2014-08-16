//
//  StreamNameGetter.m
//  Martin
//
//  Created by Tomislav Grbin on 16/08/14.
//
//

#import "StreamNameGetter.h"

@interface StreamNameGetter() <
  NSURLConnectionDelegate,
  NSURLConnectionDataDelegate
>

@property (nonatomic, strong) NSString *urlString;

@property (nonatomic, strong) NSURLConnection *urlConnection;

@property (nonatomic, strong) void (^block)(NSString *);

@end

@implementation StreamNameGetter

- (instancetype)initWithURLString:(NSString *)urlString andBlock:(void (^)(NSString *streamName))block {
  if (self = [super init]) {
    _urlString = urlString;
    _block = block;
  }
  return self;
}

- (void)start {
  NSURL *url = [NSURL URLWithString:_urlString];
  NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
  self.urlConnection = [[NSURLConnection alloc] initWithRequest:request
                                                       delegate:self
                                               startImmediately:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  NSString *name = nil;
  
  if ([response respondsToSelector:@selector(allHeaderFields)]) {
    NSDictionary *headers = ((NSHTTPURLResponse *)response).allHeaderFields;
    NSString *icyName = headers[@"icy-name"];
    
    if (icyName != nil && icyName.length > 0) {
      name = icyName;
    }
  }
  
  [self gotName:name];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  [self gotName:nil];
}

- (void)gotName:(NSString *)name {
  self.block(name);
  [self destroyConnection];
  self.block = nil;
}

- (void)destroyConnection {
  [self.urlConnection cancel];
  self.urlConnection = nil;
}

@end
