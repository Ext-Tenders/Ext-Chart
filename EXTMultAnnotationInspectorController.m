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
    
    // if so, add a new entry to the multiplicationAnnotations with some default
    // settings, including the disabled option.
    
    // refresh the tableview.
    
    // select the new row and send a double-click message to open the popover.
    return;
}

-(IBAction)deleteButtonPressed:(id)sender {
    // check to see if a row is highlighted. if not, quit.
    
    // remove this entry from the array.
    
    // deselect all rows, refresh the tableview, and refresh the chart.
    return;
}

-(IBAction)doubleClick:(id)sender {
    // check to make sure that a row is selected. if not, quit.
    
    // set up the popover, using the data from that row and the ambient sseq.
    
    // show the popover.
    return;
}

-(void)popoverWillClose:(NSNotification *)notification {
    // store the data from the popover's last state to the array.
    
    // refresh the tableview and refresh the chart.
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
        return nil;
        
    } else if ([tableColumn.identifier isEqualToString:@"enabled"]) {
        return entry[@"enabled"];
    }
    
    return @"Unimplemented column.";
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
}

@end
