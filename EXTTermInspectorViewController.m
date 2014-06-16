//
//  EXTTermInspectorViewController.m
//  Ext Chart
//
//  Created by Eric Peterson on 6/15/14.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTTermInspectorViewController.h"
#import "EXTMatrixEditor.h"
#import "EXTDocumentWindowController.h"
#import "EXTChartViewController.h"
#import "EXTTerm.h"

@interface EXTTermInspectorViewController () <NSTableViewDataSource, NSTableViewDelegate, EXTDocumentInspectorViewDelegate>

@property (strong) IBOutlet EXTMatrixEditor *zMatrixEditor;
@property (strong) IBOutlet EXTMatrixEditor *bMatrixEditor;
@property (strong) IBOutlet NSTableView *hTableView;

@end

@implementation EXTTermInspectorViewController
{
    EXTDocumentWindowController * __weak _documentWindowController;
}

#pragma mark initialization routines

- (instancetype)init {
    return [self initWithNibName:@"EXTTermInspector" bundle:nil];
}

-(void)awakeFromNib {
    self.bMatrixEditor.readonly = true;
    self.zMatrixEditor.readonly = true;
    self.bMatrixEditor.representedObject = nil;
    self.zMatrixEditor.representedObject = nil;
    
    return;
}

#pragma mark EXTDocumentInspectorViewDelegate routines

-(void)documentWindowController:(EXTDocumentWindowController *)windowController
            didAddInspectorView:(NSView *)inspectorView {
    
    _documentWindowController = windowController;
    
    return;
}

-(void)documentWindowController:(EXTDocumentWindowController *)windowController
        willRemoveInspectorView:(NSView *)inspectorView {
    
    _documentWindowController = nil;
    
    return;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selectedObject"]) {
        self.representedObject = change[NSKeyValueChangeNewKey];
        [self reloadAll];
    }
    
    return;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    if ([representedObject isKindOfClass:[EXTTerm class]]) {
        EXTTerm *term = (EXTTerm*)representedObject;
        int page = _documentWindowController.chartViewController.currentPage;
        
        int boundaryCount = ((NSArray*)term.boundaries[page]).count,
            cycleCount = ((NSArray*)term.cycles[page]).count;
        
        EXTMatrix *boundaries, *cycles;
        if (boundaryCount > 0) {
            boundaries = [EXTMatrix matrixWidth:boundaryCount height:((NSArray*)((NSArray*)term.boundaries[page])[0]).count];
            boundaries.presentation = term.boundaries[page];
        } else
            boundaries = nil;
        
        if (cycleCount > 0) {
            cycles = [EXTMatrix matrixWidth:cycleCount height:((NSArray*)((NSArray*)term.cycles[page])[0]).count];
            cycles.presentation = term.cycles[page];
        } else
            cycles = nil;
        
        self.bMatrixEditor.representedObject = boundaries;
        self.zMatrixEditor.representedObject = cycles;
        
        self.bMatrixEditor.rowNames = [term.names valueForKey:@"description"];
        self.zMatrixEditor.rowNames = [term.names valueForKey:@"description"];
    } else {
        self.bMatrixEditor.representedObject = nil;
        self.zMatrixEditor.representedObject = nil;
    }
    
    [self reloadAll];
    
    return;
}

#pragma mark NSTableView controller and data source routines

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 0;
}

-(id)tableView:(NSTableView *)tableView
        objectValueForTableColumn:(NSTableColumn *)tableColumn
           row:(NSInteger)row {
    
    return nil;
}

#pragma mark utility routines

-(void)reloadAll {
    [self.zMatrixEditor reloadData];
    [self.bMatrixEditor reloadData];
    [self.hTableView reloadData];
    
    return;
}

@end
