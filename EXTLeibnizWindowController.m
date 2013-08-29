//
//  EXTLeibnizWindowController.m
//  Ext Chart
//
//  Created by Eric Peterson on 8/27/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTLeibnizWindowController.h"
#import "EXTLocation.h"
#import "EXTTerm.h"

@interface EXTLeibnizWindowController ()

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSButton *deleteButton;
@property IBOutlet NSButton *OKButton;

@property (assign,nonatomic) NSUInteger selectedPageIndex;

// list of EXTLocations
@property (strong) NSMutableArray *list;

@end

@implementation EXTLeibnizWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)showWindow:(id)sender {
    self.list = [NSMutableArray array];
    [super showWindow:sender];
}

-(IBAction)OKPressed:(id)sender {
    [self.sseq propagateLeibniz:self.list page:self.selectedPageIndex];
    
    [self close];
    return;
}

-(IBAction)deletePressed:(id)sender {
    if (self.tableView.selectedRow == -1)
        return;
    
    [self.list removeObjectAtIndex:self.tableView.selectedRow];
    [self.tableView reloadData];
    
    return;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.list.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return ((EXTLocation*)self.list[row]).description;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"sseq"]) {
        self.sseq = change[NSKeyValueChangeNewKey];
    } else if ([keyPath isEqualToString:@"selectedPageIndex"]) {
        self.selectedPageIndex = [change[NSKeyValueChangeNewKey] intValue];
    } else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    return;
}

-(void)mouseDownAtGridLocation:(EXTIntPoint)gridLocation {
    NSArray *termsUnderClick = [self.sseq findTermsUnderPoint:gridLocation];
    
    for (int i = 0; i < termsUnderClick.count; i++) {
        EXTTerm *term = termsUnderClick[i];
        NSUInteger position = [self.list indexOfObject:term.location];
        if (position == NSNotFound) {
            [self.list addObject:term.location];
            break;
        }
    }
    
    [self.tableView reloadData];
    return;
}

@end
