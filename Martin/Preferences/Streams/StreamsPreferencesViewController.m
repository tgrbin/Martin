//
//  StreamsPreferencesViewController.m
//  Martin
//
//  Created by Tomislav Grbin on 16/08/14.
//
//

#import "StreamsPreferencesViewController.h"
#import "StreamNameGetter.h"

@interface StreamsPreferencesViewController ()

@property (strong) IBOutlet NSTextField *statusTextField;
@property (strong) IBOutlet NSProgressIndicator *indicator;

@property (nonatomic, strong) StreamNameGetter *nameGetter;

@end

@implementation StreamsPreferencesViewController

- (id)init {
  if (self = [super init]) {
    self.title = @"Streams";
  }
  return self;
}

- (IBAction)addStreamPressed:(id)sender {
  self.nameGetter = [[StreamNameGetter alloc] initWithURLString:@"http://streaming.swisstxt.ch/m/rsj/mp3_128"
                                                       andBlock:^(NSString *streamName) {
                                                         NSLog(@"got name: %@", streamName);
                                                       }];
  [self.nameGetter start];
}

@end
