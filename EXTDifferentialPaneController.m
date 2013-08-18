//
//  EXTDifferentialPaneController.m
//  Ext Chart
//
//  Created by Eric Peterson on 8/8/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTDifferentialPaneController.h"
#import "EXTDifferential.h"
#import "EXTMatrixEditor.h"

@interface EXTDifferentialPaneController ()

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSButton *addButton;
@property IBOutlet NSButton *deleteButton;

@property IBOutlet NSPopover *popover;
@property IBOutlet NSTextField *descriptionField;
@property IBOutlet NSButton *automaticallyGeneratedCB;
@property IBOutlet EXTMatrixEditor *inclusionEditor;
@property IBOutlet EXTMatrixEditor *actionEditor;

@end

@implementation EXTDifferentialPaneController
{
    EXTPartialDefinition *_partial;
}

@synthesize chartView;

#pragma mark differential inspector pane

- (id)init {
    return [self initWithNibName:@"EXTDifferentialPane" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)awakeFromNib {
    [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(doubleClick:)];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (![[self.representedObject class] isSubclassOfClass:[EXTDifferential class]])
        return 0;
    
    EXTDifferential *diff = self.representedObject;
    
    return diff.partialDefinitions.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (![[self.representedObject class] isSubclassOfClass:[EXTDifferential class]])
        return nil;
    
    EXTDifferential *diff = self.representedObject;
    EXTPartialDefinition *partial = diff.partialDefinitions[row];
    
    if ([tableColumn.identifier isEqualToString:@"dimension"]) {
        return @(partial.inclusion.width);
    } else if ([tableColumn.identifier isEqualToString:@"description"]) {
        return partial.description;
    }
    
    return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selectedObject"]) {
        self.representedObject = change[NSKeyValueChangeNewKey];
        [self.tableView reloadData];
    }
    
    return;
}

-(IBAction)deleteButtonPressed:(id)sender {
    NSInteger row = [self.tableView selectedRow];
    
    if (![[self.representedObject class] isSubclassOfClass:[EXTDifferential class]])
        return;
    
    EXTDifferential *diffl = self.representedObject;
    
    [diffl.partialDefinitions removeObjectAtIndex:row];
    
    [self.tableView deselectAll:sender];
    [self.tableView reloadData];
    [self.chartView displaySelectedPage];
    
    return;
}

-(IBAction)addButtonPressed:(id)sender {
    if (![[self.representedObject class] isSubclassOfClass:[EXTDifferential class]])
        return;
    EXTDifferential *diff = self.representedObject;
    
    EXTPartialDefinition *partial = [EXTPartialDefinition new];
    partial.inclusion = [EXTMatrix matrixWidth:0 height:diff.start.size];
    partial.action = [EXTMatrix matrixWidth:0 height:diff.end.size];
    [partial manuallyGenerated];
    
    [diff.partialDefinitions addObject:partial];
    [self.tableView reloadData];
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(diff.partialDefinitions.count-1)] byExtendingSelection:NO];
    [self doubleClick:sender];
    
    return;
}

- (void)doubleClick:(id)sender {
    if (![[self.representedObject class] isSubclassOfClass:[EXTDifferential class]])
        return;
    EXTDifferential *diff = self.representedObject;
    
    if ((self.tableView.selectedRow < 0) || (self.tableView.selectedRow >= diff.partialDefinitions.count))
        return;
    _partial = diff.partialDefinitions[self.tableView.selectedRow];
    
    // initialize the pieces of the sheet.
    if (_partial.description)
        self.descriptionField.stringValue = [_partial.description copy];
    self.inclusionEditor.representedObject = [_partial.inclusion copy];
    self.inclusionEditor.rowNames = diff.start.names;
    self.actionEditor.representedObject = [_partial.action copy];
    self.actionEditor.rowNames = diff.end.names;
    self.automaticallyGeneratedCB.state = _partial.automaticallyGenerated;
    // XXX: make this update when we edit the EXTMatrix's data.
    
    // and display
    [self.popover showRelativeToRect:[self.tableView rectOfRow:self.tableView.selectedRow] ofView:self.tableView preferredEdge:NSMinXEdge];
    [self.inclusionEditor reloadData];
    [self.actionEditor reloadData];
    
    return;
}

#pragma mark differential editor popover

- (void)popoverWillClose:(NSNotification *)notification {
    if (![_partial.description isEqualToString:self.descriptionField.stringValue] ||
        ![self.inclusionEditor.representedObject isEqual:_partial.inclusion] ||
        ![self.actionEditor.representedObject isEqual:_partial.action])
        [_partial manuallyGenerated];
    
    _partial.description = self.descriptionField.stringValue;
    _partial.inclusion = self.inclusionEditor.representedObject;
    _partial.action = self.actionEditor.representedObject;
    
    [_tableView reloadData];
    [self.chartView displaySelectedPage];
    
    return;
}

@end
