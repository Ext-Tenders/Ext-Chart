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
#import "EXTChartViewController.h"

@interface EXTLeibnizWindowController ()

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSButton *deleteButton;
@property IBOutlet NSButton *OKButton;

// list of EXTLocations
@property (strong) NSMutableArray *list;

@end

@implementation EXTLeibnizWindowController

- (void)showWindow:(id)sender {
    [self.tableView deselectAll:nil];
    self.list = [NSMutableArray array];
    [self.tableView reloadData];
    [super showWindow:sender];
}

-(IBAction)OKPressed:(id)sender {
    [self.documentWindowController.extDocument.sseq propagateLeibniz:self.list page:self.documentWindowController.chartViewController.currentPage];
    [self.documentWindowController.chartViewController reloadCurrentPage];

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

-(void)mouseDownAtGridLocation:(EXTIntPoint)gridLocation {
    NSArray *termsUnderClick = [self.documentWindowController.extDocument.sseq findTermsUnderPoint:gridLocation];
    
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
