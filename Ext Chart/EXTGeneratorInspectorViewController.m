//
//  EXTGeneratorInspectorViewController.m
//  Ext Chart
//
//  Created by Eric Peterson on 8/1/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTGeneratorInspectorViewController.h"
#import "EXTDocumentWindowController.h"
#import "EXTChartViewController.h"
#import "EXTPolynomialSSeq.h"

@interface EXTGeneratorInspectorViewController () <EXTDocumentInspectorViewDelegate, NSTableViewDelegate, NSTableViewDataSource>
@property(nonatomic, strong) IBOutlet NSTableView *tableView;
@property(nonatomic, strong) IBOutlet NSTextField *textField;
@property(nonatomic, strong) EXTSpectralSequence *sseq;
@property(nonatomic, strong) NSMutableArray *generators;
@property(nonatomic, weak) EXTDocumentWindowController *documentWindowController;
@end

@implementation EXTGeneratorInspectorViewController

#pragma mark - Life cycle

- (instancetype)init {
    return [self initWithNibName:@"EXTGeneratorInspectorView" bundle:nil];
}

- (void)awakeFromNib {
    [self.textField setTarget:self];
    [self.textField setAction:@selector(addButtonPressed:)];
}

#pragma mark - Properties

- (void)setSseq:(EXTSpectralSequence *)sseq {
    _sseq = sseq;
    
    if ([sseq isKindOfClass:[EXTPolynomialSSeq class]]) {
        [self unbind:@"generators"];
        [self bind:@"generators" toObject:sseq withKeyPath:@"generators" options:nil];
    } else {
        [self unbind:@"generators"];
        self.generators = nil;
    }
    
    [_tableView reloadData];
}

#pragma mark - EXTDocumentInspectorViewDelegate

- (void)documentWindowController:(EXTDocumentWindowController *)windowController didAddInspectorView:(NSView *)inspectorView {
    [self bind:@"sseq" toObject:windowController.document withKeyPath:@"sseq" options:nil];
    self.documentWindowController = windowController;
}

- (void)documentWindowController:(EXTDocumentWindowController *)windowController willRemoveInspectorView:(NSView *)inspectorView {
    [self unbind:@"generators"];
    [self unbind:@"sseq"];

    self.generators = nil;
    self.sseq = nil;
    self.documentWindowController = nil;
}

#pragma mark - NSTableViewDataSource

-(NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView {
    return self.generators.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSAssert(row >= 0 && row < self.generators.count, @"Table view row index is out of bounds");
    
    if ([[tableColumn identifier] isEqualToString:@"location"])
        return [_sseq.locConvertor convertToString:[[self.generators objectAtIndex:row] objectForKey:[tableColumn identifier]]];

    return [[[self.generators objectAtIndex:row] objectForKey:[tableColumn identifier]] description];
}

-(void) tableView:(NSTableView*)aTableView
   setObjectValue:(id)object
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row {
    if (![_sseq isKindOfClass:[EXTPolynomialSSeq class]])
        return;
    EXTPolynomialSSeq *polySSeq = (EXTPolynomialSSeq*)_sseq;
    
    if ([[tableColumn identifier] isEqualToString:@"name"]) {
        [polySSeq changeName:[polySSeq.generators[row] objectForKey:@"name"]
                          to:object];
    } else if ([[tableColumn identifier] isEqualToString:@"upperBound"]) {
        [polySSeq resizePolyClass:[polySSeq.generators[row] objectForKey:@"name"] upTo:[object intValue]];
        [self causeRefresh];
    }
    
    return;
}

-(void) causeRefresh {
    if (_documentWindowController.chartViewController.currentPage > 0) {
        _documentWindowController.chartViewController.currentPage = 0;
    } else {
        [_documentWindowController.chartViewController reloadCurrentPage];
    }
    
    return;
}

-(IBAction)addButtonPressed:(id)sender {
    if (![_sseq isKindOfClass:[EXTPolynomialSSeq class]])
        return;
    
    EXTPolynomialSSeq *polySSeq = (EXTPolynomialSSeq*) _sseq;
    EXTLocation *loc =
        [polySSeq.locConvertor convertFromString:[self.textField stringValue]];
    
    if (!loc)
        return;
    
    // it liiiiives!
    [polySSeq addPolyClass:nil location:loc upTo:1];
    [_documentWindowController.document updateChangeCount:NSChangeDone];
    
    [_tableView reloadData];
    [self causeRefresh];
}

-(IBAction)deleteButtonPressed:(id)sender {
    NSInteger row = [_tableView selectedRow];
    
    if (![_sseq isKindOfClass:[EXTPolynomialSSeq class]])
        return;
    
    EXTPolynomialSSeq *polySSeq = (EXTPolynomialSSeq*)_sseq;
    [polySSeq deleteClass:[polySSeq.generators[row] objectForKey:@"name"]];
    [_documentWindowController.document updateChangeCount:NSChangeDone];
    
    [_tableView deselectAll:sender];
    [_tableView reloadData];
    
    [self causeRefresh];
    
    return;
}

@end
