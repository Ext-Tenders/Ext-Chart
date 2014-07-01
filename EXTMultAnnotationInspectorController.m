//
//  EXTMultAnnotationInspectorController.m
//  Ext Chart
//
//  Created by Eric Peterson on 6/29/14.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTMultAnnotationInspectorController.h"
#import "EXTMatrixEditor.h"
#import "EXTDocumentWindowController.h"
#import "EXTSpectralSequence.h"
#import "EXTDocument.h"
#import "EXTTerm.h"
#import "EXTChartViewController.h"

@interface EXTMultAnnotationInspectorController () <EXTDocumentInspectorViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSPopoverDelegate>

@property IBOutlet NSTableView *table;
@property IBOutlet NSButton *addButton;
@property IBOutlet NSButton *deleteButton;

@property IBOutlet EXTMatrixEditor *matrixEditor;
@property IBOutlet NSPopover *popover;

@property NSMutableArray *multiplicationAnnotations;
@property EXTSpectralSequence *sseq;
@property id selectedObject;
@property EXTDocumentWindowController *documentWindowController;

@end

@implementation EXTMultAnnotationInspectorController

#pragma mark --- binding and initialization things

- (instancetype)init {
    if (self = [self initWithNibName:@"EXTMultAnnotationInspectorView" bundle:nil]) {
    }
    
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)awakeFromNib {
    [self.table setTarget:self];
    [self.table setDoubleAction:@selector(doubleClick:)];
    
    return;
}

- (void)documentWindowController:(EXTDocumentWindowController *)windowController didAddInspectorView:(NSView *)inspectorView {
    [self bind:@"multiplicationAnnotations" toObject:windowController.document withKeyPath:@"multiplicationAnnotations" options:nil];
    [self bind:@"sseq" toObject:windowController.document withKeyPath:@"sseq" options:nil];
    [self bind:@"selectedObject" toObject:windowController.chartViewController withKeyPath:@"selectedObject" options:nil];
    self.documentWindowController = windowController;
    
    return;
}

- (void)documentWindowController:(EXTDocumentWindowController *)windowController willRemoveInspectorView:(NSView *)inspectorView {
    [self unbind:@"multiplicationAnnotations"];
    [self unbind:@"sseq"];
    [self unbind:@"selectedObject"];
    
    self.selectedObject = nil;
    self.sseq = nil;
    self.multiplicationAnnotations = nil;
    self.documentWindowController = nil;
    
    return;
}

#pragma mark --- button user interactions

-(IBAction)addButtonPressed:(id)sender {
    // check to see if an EXTTerm is presently highlighted. if not, quit.
    if (![self.selectedObject isKindOfClass:[EXTTerm class]]
        || !self.multiplicationAnnotations || !self.sseq)
        return;
    
    EXTTerm *term = self.selectedObject;
    
    // if so, add a new entry to the multiplicationAnnotations with some default
    // settings, including the disabled option.
    NSMutableDictionary *anno = [NSMutableDictionary new];
    anno[@"location"] = term.location;
    anno[@"vector"] = [EXTMatrix matrixWidth:1 height:term.size].presentation[0];
    anno[@"enabled"] = @(false);
    
    [self.multiplicationAnnotations addObject:anno];
    
    // refresh the tableview.
    [self.table reloadData];
    
    // select the new row and send a double-click message to open the popover.
    [self.table selectRowIndexes:[NSIndexSet indexSetWithIndex:(self.multiplicationAnnotations.count-1)] byExtendingSelection:NO];
    [self doubleClick:sender];
    
    return;
}

-(IBAction)deleteButtonPressed:(id)sender {
    // check to see if a row is highlighted. if not, quit.
    int row = self.table.selectedRow;
    
    if (!self.multiplicationAnnotations ||
        row < 0 ||
        row >= self.multiplicationAnnotations.count)
        return;
    
    // remove this entry from the array.
    [self.table deselectAll:nil];
    [self.multiplicationAnnotations removeObjectAtIndex:row];
    
    // refresh the tableview, and refresh the chart.
    [self.table reloadData];
    [self.documentWindowController.chartViewController reloadCurrentPage];
    return;
}

-(IBAction)doubleClick:(id)sender {
    // check to make sure that a row is selected. if not, quit.
    int row = self.table.selectedRow;
    
    if (!self.multiplicationAnnotations ||
        row < 0 ||
        row >= self.multiplicationAnnotations.count)
        return;
    
    NSMutableDictionary *entry = self.multiplicationAnnotations[row];
    EXTTerm *term = [self.sseq findTerm:entry[@"location"]];
    
    // set up the popover, using the data from that row and the ambient sseq.
    self.matrixEditor.representedObject = [EXTMatrix matrixWidth:1 height:term.size];
    if (((NSArray*)entry[@"vector"]).count == self.matrixEditor.representedObject.height) {
        self.matrixEditor.representedObject.presentation[0] = entry[@"vector"];
    }
    self.matrixEditor.rowNames = [term.names valueForKey:@"description"];
    
    // show the popover.
    [self.popover showRelativeToRect:[_table rectOfRow:_table.selectedRow]
                              ofView:_table
                       preferredEdge:NSMinXEdge];
    [self.matrixEditor reloadData];
    
    return;
}

-(void)popoverWillClose:(NSNotification *)notification {
    // refresh the tableview and refresh the chart.
    [self.matrixEditor reloadData];
    [self.documentWindowController.chartViewController reloadCurrentPage];
    
    return;
}

#pragma mark --- tableViewDataSource messages

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (!self.multiplicationAnnotations)
        return 0;
    
    return self.multiplicationAnnotations.count;
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row {
    if (!self.multiplicationAnnotations ||
        row < 0 ||
        row >= self.multiplicationAnnotations.count)
            return nil;
    
    NSMutableDictionary *entry = self.multiplicationAnnotations[row];
    
    if ([tableColumn.identifier isEqualToString:@"element"]) {
        EXTTerm *term = [self.sseq findTerm:entry[@"location"]];
        if (!term)
            return @"Term not found.";
        
        return [term nameForVector:entry[@"vector"]];
        
    } else if ([tableColumn.identifier isEqualToString:@"style"]) {
        // just return nil for now.
        return @"unimpl.";
        
    } else if ([tableColumn.identifier isEqualToString:@"enabled"]) {
        return entry[@"enabled"];
    }
    
    return @"Unimplemented column.";
}

- (void)tableView:(NSTableView *)tableView
   setObjectValue:(id)object
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row {
    if (!self.multiplicationAnnotations ||
        row < 0 ||
        row >= self.multiplicationAnnotations.count)
        return;
    
    NSMutableDictionary *entry = self.multiplicationAnnotations[row];
    
    if ([tableColumn.identifier isEqualToString:@"element"]) {
        return;
        
    } else if ([tableColumn.identifier isEqualToString:@"style"]) {
        // do nothing for now.
        return;
        
    } else if ([tableColumn.identifier isEqualToString:@"enabled"]) {
        entry[@"enabled"] = object;
        [self.documentWindowController.chartViewController reloadCurrentPage];
        
        return;
    }
    
    DLog(@"Unimplemented column \"%@\".", tableColumn.identifier);
    return;
}

@end
