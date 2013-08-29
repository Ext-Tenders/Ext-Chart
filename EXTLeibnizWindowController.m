//
//  EXTLeibnizWindowController.m
//  Ext Chart
//
//  Created by Eric Peterson on 8/27/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTLeibnizWindowController.h"
#import "EXTSpectralSequence.h"
#import "EXTLocation.h"

@interface EXTLeibnizWindowController ()

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSButton *deleteButton;
@property IBOutlet NSButton *OKButton;

@property (weak,nonatomic) EXTSpectralSequence *sseq;
@property (assign,nonatomic,readonly) NSUInteger page;

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
    [self.sseq propagateLeibniz:self.list page:self.page];
    
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

@end
