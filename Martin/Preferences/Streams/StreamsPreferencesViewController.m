//
//  StreamsPreferencesViewController.m
//  Martin
//
//  Created by Tomislav Grbin on 16/08/14.
//
//

#import "StreamsPreferencesViewController.h"
#import "MartinAppDelegate.h"
#import "Stream.h"
#import "DragDataConverter.h"

#import "StreamsController+urlPrompt.h"
#import "NSString+Stream.h"
#import "NSObject+Observe.h"
#import "NSProgressIndicator+ShowHide.h"

@interface StreamsPreferencesViewController () <
  NSTableViewDataSource,
  NSTabViewDelegate
>

@property (nonatomic, weak) StreamsController *streamsController;

@property (nonatomic, assign) BOOL showStreamsCheckbox;

@property (nonatomic, strong) IBOutlet NSTextField *statusTextField;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *indicator;

@property (nonatomic, strong) IBOutlet NSTableView *tableView;

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

- (void)awakeFromNib {
  [_tableView registerForDraggedTypes:@[kDragTypeStreamRow]];
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
    [_indicator hide];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      _statusTextField.stringValue = @"";
    });
  } else {
    [_indicator show];
  }
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

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
  NSString *newValue = fieldEditor.string;
  
  Stream *stream = _streamsController.streams[_tableView.editedRow];
  BOOL editedName = (_tableView.editedColumn == 0);
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (editedName == YES) {
      stream.name = newValue;
    } else {
      stream.urlString = [newValue URLify];
    }
  });
  
  return YES;
}

- (BOOL)tableView:(NSTableView *)tableView
        writeRows:(NSArray *)rows
     toPasteboard:(NSPasteboard *)pboard
{
  [pboard declareTypes:@[kDragTypeStreamRow] owner:nil];
  [pboard setData:[DragDataConverter dataFromArray:rows]
          forType:kDragTypeStreamRow];
  return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
  [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
  return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)dropOperation
{
  NSString *draggingType = [info.draggingPasteboard.types lastObject];
  
  if ([draggingType isEqualToString:kDragTypeStreamRow]) {
    NSArray *items = [DragDataConverter arrayFromData:[info.draggingPasteboard dataForType:kDragTypeStreamRow]];
    
    int srcRow = [items[0] intValue];
    if (srcRow < row) {
      --row;
    }
    
    [_streamsController reorderStreamAtIndex:srcRow toNewIndex:row];
    
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
  }
  
  return YES;
}

@end
