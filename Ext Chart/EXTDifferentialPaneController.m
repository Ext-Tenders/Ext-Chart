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
#import "EXTDocumentWindowController.h"
#import "EXTChartViewController.h"
#import "EXTMaySpectralSequence.h"

@interface EXTDifferentialPaneController () <EXTDocumentInspectorViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, EXTMatrixEditorDelegate>

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSButton *addButton;
@property (nonatomic, weak) IBOutlet NSButton *deleteButton;
@property (nonatomic, weak) IBOutlet NSButton *nakamuraButton;

@property (nonatomic, weak) IBOutlet NSPopover *popover;
@property (nonatomic, weak) IBOutlet NSTextField *descriptionField;
@property (nonatomic, weak) IBOutlet NSTextField *dimensionField;
@property (nonatomic, weak) IBOutlet NSButton *automaticallyGeneratedCB;
@property (nonatomic, weak) IBOutlet EXTMatrixEditor *inclusionEditor;
@property (nonatomic, weak) IBOutlet EXTMatrixEditor *actionEditor;

@property (nonatomic, weak) IBOutlet NSPopover *nakamuraPopover;
@property IBOutlet EXTMatrixEditor *sourceEditor;
@property IBOutlet EXTMatrixEditor *targetEditor;
@property IBOutlet NSTextField *field;
@property IBOutlet NSStepper *stepper;
@property IBOutlet NSButton *OKbutton;
@property (assign) int degree;

@end



@implementation EXTDifferentialPaneController
{
    EXTPartialDefinition *_partial;
    EXTDocumentWindowController * __weak _documentWindowController;
}

#pragma mark differential inspector pane, initialization

- (instancetype)init {
    if (self = [self initWithNibName:@"EXTDifferentialPane" bundle:nil]) {
        self.degree = 0;
    }
    
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)awakeFromNib {
    [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(doubleClick:)];
    self.targetEditor.readonly = true;
    self.sourceEditor.delegate = self;
    
    return;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"selectedObject"]) {
        self.representedObject = change[NSKeyValueChangeNewKey];
        [self.tableView reloadData];
        
        if ([((EXTDocument*)_documentWindowController.document).sseq isKindOfClass:[EXTMaySpectralSequence class]])
            [self.nakamuraButton setEnabled:YES];
        else
            [self.nakamuraButton setEnabled:NO];
    }
    
    return;
}

#pragma mark differential inspector pane, tableview delegate messages

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (![self.representedObject isKindOfClass:[EXTDifferential class]])
        return 0;
    
    EXTDifferential *diff = self.representedObject;
    
    return diff.partialDefinitions.count;
}

- (id)tableView:(NSTableView *)tableView
        objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row {
    if (![self.representedObject isKindOfClass:[EXTDifferential class]])
        return nil;
    
    EXTDifferential *diff = self.representedObject;
    
    if (row < 0 || row >= diff.partialDefinitions.count)
        return nil;
    
    EXTPartialDefinition *partial = diff.partialDefinitions[row];
    
    if ([tableColumn.identifier isEqualToString:@"dimension"]) {
        return @(partial.inclusion.width);
    } else if ([tableColumn.identifier isEqualToString:@"description"]) {
        return partial.description;
    }
    
    return nil;
}

#pragma mark differential inspector pane, button press messages

-(IBAction)deleteButtonPressed:(id)sender {
    NSInteger row = [self.tableView selectedRow];
    
    if (![self.representedObject isKindOfClass:[EXTDifferential class]])
        return;
    
    EXTDifferential *diffl = self.representedObject;
    
    if (row < 0 || row >= diffl.partialDefinitions.count) {
        [_documentWindowController.chartViewController reloadCurrentPage];
        return;
    }
    
    [diffl.partialDefinitions removeObjectAtIndex:row];
    
    [self.tableView deselectAll:sender];
    [self.tableView reloadData];
    [_documentWindowController.chartViewController reloadCurrentPage];

    return;
}

-(IBAction)addButtonPressed:(id)sender {
    if (![self.representedObject isKindOfClass:[EXTDifferential class]])
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
    if (![self.representedObject isKindOfClass:[EXTDifferential class]])
        return;
    EXTDifferential *diff = self.representedObject;
    
    if ((self.tableView.selectedRow < 0) ||
        (self.tableView.selectedRow >= diff.partialDefinitions.count))
        return;
    _partial = diff.partialDefinitions[self.tableView.selectedRow];
    
    // initialize the pieces of the sheet.
    if (_partial.description)
        self.descriptionField.stringValue = [_partial.description copy];
    self.dimensionField.stringValue = [NSString stringWithFormat:@"%ld",
                                       _partial.inclusion.width];
    self.inclusionEditor.representedObject = [_partial.inclusion copy];
    self.inclusionEditor.rowNames =
                                [diff.start.names valueForKey:@"description"];
    self.actionEditor.representedObject = [_partial.action copy];
    self.actionEditor.rowNames = [diff.end.names valueForKey:@"description"];
    self.automaticallyGeneratedCB.state = _partial.automaticallyGenerated;
    // XXX: make this update when we edit the EXTMatrix's data.
    
    // and display
    [self.popover
        showRelativeToRect:[_tableView rectOfRow:_tableView.selectedRow]
                    ofView:_tableView
             preferredEdge:NSMinXEdge];
    [self.inclusionEditor reloadData];
    [self.actionEditor reloadData];
    
    return;
}

-(IBAction)nakamuraButtonPressed:(id)sender {
    if (![self.representedObject isKindOfClass:[EXTDifferential class]])
        return;
    
    EXTDifferential *diff = (EXTDifferential*)self.representedObject;
    
    self.degree = 0;
    self.sourceEditor.representedObject = [EXTMatrix matrixWidth:1 height:diff.start.names.count];
    self.sourceEditor.rowNames = [diff.start.names valueForKey:@"description"];
    [self.sourceEditor reloadData];
    self.targetEditor.representedObject = nil;
    [self.targetEditor reloadData];
    
    [self.nakamuraPopover showRelativeToRect:self.nakamuraButton.frame ofView:self.nakamuraButton preferredEdge:NSMinXEdge];
    
    return;
}

#pragma mark differential editor popover

- (void)popoverWillClose:(NSNotification *)notification {
    if (self.popover.shown) {
        if (![_partial.description isEqualToString:self.descriptionField.stringValue] ||
            ![self.inclusionEditor.representedObject isEqual:_partial.inclusion] ||
            ![self.actionEditor.representedObject isEqual:_partial.action])
            [_partial manuallyGenerated];
    
        _partial.description = self.descriptionField.stringValue;
        _partial.inclusion = self.inclusionEditor.representedObject;
        _partial.action = self.actionEditor.representedObject;
    
        [_tableView reloadData];
        [_documentWindowController.chartViewController reloadCurrentPage];
    } else if (self.nakamuraPopover.shown) {
        // nakamura popover is closing.
        // probably this is not important for cleanup.
    }

    return;
}

-(IBAction)dimensionFieldWasEdited:(id)sender {
    NSUInteger value = self.dimensionField.intValue;
    EXTMatrix *inclusion = self.inclusionEditor.representedObject;
    EXTMatrix *action = self.actionEditor.representedObject;
    
    // three things can happen.
    // first, if this is the same dimension, we don't need to do anything.
    if (value == inclusion.width)
        return;
    
    EXTMatrix *newInclusion = [EXTMatrix matrixWidth:value height:inclusion.height],
              *newAction = [EXTMatrix matrixWidth:value height:action.height];
    
    // or, if this dimension is smaller than the one we were, we should modify
    // the dimensions of our matrices and lop them off / extend accordingly.
    memcpy(newInclusion.presentation.mutableBytes, inclusion.presentation.mutableBytes, inclusion.presentation.length);
    memcpy(newAction.presentation.mutableBytes, action.presentation.mutableBytes, action.presentation.length);
    
    // store the fresh matrices
    self.actionEditor.representedObject = newAction;
    self.inclusionEditor.representedObject = newInclusion;
    
    // since we changed something, we should have the matrix editors reload.
    [self.inclusionEditor reloadData];
    [self.actionEditor reloadData];
    
    return;
}

#pragma mark - EXTDocumentInspectorViewDelegate

- (void)documentWindowController:(EXTDocumentWindowController *)windowController didAddInspectorView:(NSView *)inspectorView {
    _documentWindowController = windowController;
}

- (void)documentWindowController:(EXTDocumentWindowController *)windowController willRemoveInspectorView:(NSView *)inspectorView {
    _documentWindowController = nil;
}

#pragma mark - Nakamura's lemma routines

-(void)matrixEditorDidUpdate {
    [self recomputeRHS];
}

-(IBAction)OKPressed:(id)sender {
    // actually do the nakamura calculation.
    EXTMaySpectralSequence *sseq = ((EXTMaySpectralSequence*)((EXTDocument*)_documentWindowController.document).sseq);
    EXTDifferential *diff = (EXTDifferential*)self.representedObject;
    
    NSMutableArray *column = [NSMutableArray arrayWithCapacity:self.sourceEditor.representedObject.height];
    for (int i = 0; i < self.sourceEditor.representedObject.height; i++)
        column[i] = @(((int*)self.sourceEditor.representedObject.presentation.mutableBytes)[i]);
    
    //EXTDifferential *resultingDiff =
        [sseq applyNakamura:self.degree
                   toVector:column
                 atLocation:(EXTTriple*)diff.start.location
                     onPage:_documentWindowController.chartViewController.currentPage];
    
    // maybe change the page and select the new differential?
    
    [_documentWindowController.chartViewController reloadCurrentPage];
    [self.nakamuraPopover close];
    return;
}

-(IBAction)changeDegreeValue:(id)sender {
    self.degree = [sender intValue];
    [self.field setIntegerValue:self.degree];
    [self.stepper setIntegerValue:self.degree];
    
    [self recomputeRHS];
    
    return;
}

-(void)recomputeRHS {
    EXTDifferential *diff = (EXTDifferential*)self.representedObject;
    EXTTerm *term = diff.start;
    EXTMaySpectralSequence *sseq = ((EXTMaySpectralSequence*)((EXTDocument*)_documentWindowController.document).sseq);
    
    NSMutableArray *vector = [NSMutableArray arrayWithCapacity:self.sourceEditor.representedObject.height];
    for (int i = 0; i < self.sourceEditor.representedObject.height; i++)
    vector[i] = @(((int*)self.sourceEditor.representedObject.presentation.mutableBytes)[i]);
    
    NSArray *output = [sseq applySquare:self.degree
                               toVector:vector
                             atLocation:(EXTTriple*)term.location];
    
    // it's possible for nakamura to fail, whereupon we should empty the table
    if (!output) {
        self.targetEditor.representedObject = nil;
        [self.targetEditor reloadData];
        
        return;
    }
    
    EXTTerm *endTerm = output[1];
    EXTMatrix *resultMatrix = [EXTMatrix matrixWidth:1 height:endTerm.names.count];
    for (int i = 0; i < ((NSArray*)output[0]).count; i++)
        ((int*)resultMatrix.presentation.mutableBytes)[i] = [output[0][i] intValue];
    
    self.targetEditor.representedObject = resultMatrix;
    self.targetEditor.rowNames = [endTerm.names valueForKey:@"description"];
    [self.targetEditor reloadData];
    
    return;
}

-(void)controlTextDidChange:(NSNotification *)obj {
    int value = [((NSTextView*)obj.userInfo[@"NSFieldEditor"]).textStorage.string integerValue];
    
    [self changeDegreeValue:@(value)];
}


@end
