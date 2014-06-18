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
    NSDictionary *homologyReps;
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

    [self.bMatrixEditor reloadData];
    [self.zMatrixEditor reloadData];
    
    homologyReps = nil;
    
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
        
        homologyReps = [EXTMatrix findOrdersOf:boundaries in:cycles];
    } else {
        self.bMatrixEditor.representedObject = nil;
        self.zMatrixEditor.representedObject = nil;
        homologyReps = nil;
    }
    
    [self reloadAll];
    
    return;
}

#pragma mark NSTableView controller and data source routines

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (!homologyReps)
        return 0;
    
    return homologyReps.allKeys.count;
}

-(id)tableView:(NSTableView *)tableView
        objectValueForTableColumn:(NSTableColumn *)tableColumn
           row:(NSInteger)row {
    if (!self.representedObject ||
        ![self.representedObject isKindOfClass:[EXTTerm class]] ||
        !homologyReps)
        return nil;
    
    EXTTerm *term = (EXTTerm*)self.representedObject;
    NSArray *allKeys = homologyReps.allKeys;
    
    if (row < 0 || row >= allKeys.count)
        return nil;
    
    NSArray *vector = allKeys[row];
    
    if ([tableColumn.identifier isEqualToString:@"order"]) {
        int order = [homologyReps[vector] intValue];
        
        // XXX: over torsion ground rings, that "∞" should be the actual order
        // of the element in the ring.
        if (order)
            return [NSString stringWithFormat:@"%d", order];
        else
            return @"∞";
    } else if ([tableColumn.identifier isEqualToString:@"vector"]) {
        NSString *ret = @"";
        
        for (int i = 0; i < vector.count; i++) {
            if ([ret isEqualToString:@""]) {
                if ([vector[i] intValue] == 1)
                    ret = [NSString stringWithFormat:@"%@", term.names[i]];
                else if ([vector[i] intValue] != 0)
                    ret = [NSString stringWithFormat:@"%@ %@", vector[i], term.names[i]];
                // if vector[i] is zero, don't do anything.
                continue;
            }
            
            if ([vector[i] intValue] > 1)
                ret = [NSString stringWithFormat:@"%@ + %@ %@",
                       ret, vector[i], term.names[i]];
            else if ([vector[i] intValue] == 1)
                ret = [NSString stringWithFormat:@"%@ + %@",
                       ret, term.names[i]];
            else if ([vector[i] intValue] < 0)
                ret = [NSString stringWithFormat:@"%@ - %@ %@",
                       ret, @(-[vector[i] intValue]), term.names[i]];
        }
        
        return ret;
    }
    
    // else
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
