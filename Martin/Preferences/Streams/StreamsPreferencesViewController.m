//
//  StreamsPreferencesViewController.m
//  Martin
//
//  Created by Tomislav Grbin on 16/08/14.
//
//

#import "StreamsPreferencesViewController.h"
#import "StreamsController.h"
#import "MartinAppDelegate.h"
#import "Stream.h"

#import "StreamsController+urlPrompt.h"
#import "NSObject+Observe.h"

@interface StreamsPreferencesViewController () <
  NSTableViewDataSource,
  NSTabViewDelegate
>

@property (nonatomic, weak) StreamsController *streamsController;

@property (nonatomic, assign) BOOL showStreamsCheckbox;

@property (strong) IBOutlet NSTextField *statusTextField;
@property (strong) IBOutlet NSProgressIndicator *indicator;

@property (strong) IBOutlet NSTableView *tableView;

@end

@implementation StreamsPreferencesViewController

- (id)init {
  if (self = [super init]) {
    self.title = @"Streams";
    _streamsController = [MartinAppDelegate get].streamsController;
    _showStreamsCheckbox = _streamsController.showStreamsInLibraryPane;
    
    [self observe:kStreamsUpdatedNotification
       withAction:@selector(streamsUpdated)];
  }
  return self;
}

#pragma mark - actions

- (IBAction)addStreamPressed:(id)sender {
  NSString *urlString = [StreamsController urlPrompt];
  
  if (urlString != nil && urlString.length > 0) {
    Stream *stream = [_streamsController streamWithURLString:urlString];
    
    if (stream) {
      [self showMessage:@"Stream already added." hideAutomatically:YES];
      
      // TODO: scroll to and select that stream
    } else {
      stream = [_streamsController createStreamWithURLString:urlString];
     
      [self showMessage:@"Trying to get stream name..." hideAutomatically:NO];
      
      [stream sendRequestForStreamNameWithCompletionBlock:^(StreamNameRequestOutcome outcome) {
        
        if (outcome == kStreamNameRequestOutcomeSuccessfulyUpdatedName) {
          
          [self showMessage:[NSString stringWithFormat:@"Got stream name: %@", stream.name]
          hideAutomatically:YES];
          
        } else if (outcome == kStreamNameRequestOutcomeNoName) {
          
          [self showMessage:@"Couldn't get stream name." hideAutomatically:YES];
          
        } else if (outcome == kStreamNameRequestOutcomeConnectionFailed) {
          
          [self showMessage:@"Couldn't connect to stream." hideAutomatically:YES];
          
        }
      }];
    }
  }
}

- (void)setShowStreamsCheckbox:(BOOL)showStreamsCheckbox {
  _showStreamsCheckbox = showStreamsCheckbox;
  _streamsController.showStreamsInLibraryPane = _showStreamsCheckbox;
}

- (IBAction)removePressed:(id)sender {
  Stream *clickedStream = _streamsController.streams[_tableView.clickedRow];
  [_streamsController removeStream:clickedStream];
}

- (void)streamsUpdated {
  [_tableView reloadData];
}

#pragma mark - util

- (void)showMessage:(NSString *)message
  hideAutomatically:(BOOL)hideAutomatically {
  _statusTextField.stringValue = message;
  
  if (hideAutomatically == YES) {
    [self hideSpinner];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      _statusTextField.stringValue = @"";
    });
  } else {
    [self showSpinner];
  }
}

// TODO: this is also used in last fm
- (void)showSpinner {
  _indicator.hidden = NO;
  [_indicator startAnimation:nil];
}

- (void)hideSpinner {
  _indicator.hidden = YES;
  [_indicator stopAnimation:nil];
}

#pragma mark - table view

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return _streamsController.streams.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSString *identifier = tableColumn.identifier;
  
  if ([identifier isEqualToString:@"remove"]) {
    return nil;
  } else {
    Stream *stream = _streamsController.streams[row];
    
    if ([identifier isEqualToString:@"name"]) {
      return stream.name;
    } else {
      return stream.urlString;
    }
  }
}

@end
