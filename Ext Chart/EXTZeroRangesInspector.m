//
//  EXTZeroRangesInspector.m
//  Ext Chart
//
//  Created by Eric Peterson on 9/28/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTZeroRangesInspector.h"
#import "EXTSpectralSequence.h"
#import "EXTDocumentWindowController.h"
#import "EXTSpectralSequence.h"
#import "EXTLocation.h"

@interface EXTZeroRangesInspector () <NSTableViewDataSource, NSTableViewDelegate, NSPopoverDelegate, EXTDocumentInspectorViewDelegate>

@property IBOutlet NSPopover *popover;
@property IBOutlet NSTableView *tableView;
@property IBOutlet NSButton *addButton;
@property IBOutlet NSButton *deleteButton;
@property IBOutlet NSButton *dropdownMenu;

@property IBOutlet NSTextField *leftEdge;
@property IBOutlet NSTextField *bottomEdge;
@property IBOutlet NSTextField *backEdge;
@property IBOutlet NSTextField *rightEdge;
@property IBOutlet NSTextField *topEdge;
@property IBOutlet NSTextField *frontEdge;

@property (weak) NSWindowController *documentWindowController;
@property (weak,nonatomic) EXTSpectralSequence *sseq;
@property (weak,nonatomic) NSMutableArray *zeroRanges;
@property (weak,nonatomic) EXTZeroRange *activeZR;

@end

@implementation EXTZeroRangesInspector
{
    EXTSpectralSequence *_sseq;
    NSArray *_zeroRanges;
}

- (instancetype)init {
    return (self = [self initWithNibName:@"EXTZeroRangesInspector" bundle:nil]);
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)awakeFromNib {
    [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(doubleClick:)];
}

-(IBAction) deleteButtonPressed:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if ((row < 0) || (row >= self.zeroRanges.count))
        return;
    
    [self.zeroRanges removeObjectAtIndex:row];
    [self.tableView deselectAll:sender];
    [self.tableView reloadData];
}

-(IBAction) addButtonPressed:(id)sender {
    
    switch (self.dropdownMenu.selectedTag) {
        case 0: {
            if ([[EXTPair class] isSubclassOfClass:_sseq.indexClass])
                [self.zeroRanges addObject:[EXTZeroRangePair new]];
            else if ([[EXTTriple class] isSubclassOfClass:_sseq.indexClass])
                [self.zeroRanges addObject:[EXTZeroRangeTriple new]];
            else
                return;
            
            break;
        }
            
        case 1:
            [self.zeroRanges addObject:[EXTZeroRangeStrict newWithSSeq:self.sseq]];
            break;
            
        default:
            return;
    }
    
    [self.tableView reloadData];
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(self.zeroRanges.count-1)] byExtendingSelection:NO];
    [self doubleClick:sender];
    
    return;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.sseq.zeroRanges count];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row >= [self.sseq.zeroRanges count])
        return nil;
    
    EXTZeroRange *zeroRange = self.sseq.zeroRanges[row];
    if ([tableColumn.identifier isEqualToString:@"kind"]) {
        if ([zeroRange isKindOfClass:[EXTZeroRangePair class]] ||
            [zeroRange isKindOfClass:[EXTZeroRangeTriple class]])
            return @"Cube";
        else if ([zeroRange isKindOfClass:[EXTZeroRangeStrict class]])
            return @"Strict";
        else
            return @"Unknown";
    } else if ([tableColumn.identifier isEqualToString:@"description"]) {
        if ([zeroRange isKindOfClass:[EXTZeroRangePair class]]) {
            EXTZeroRangePair *zrPair = (EXTZeroRangePair*)zeroRange;
            return [NSString stringWithFormat:@"(%d, %d) → (%d, %d)",
                    zrPair.leftEdge, zrPair.bottomEdge,
                    zrPair.rightEdge, zrPair.topEdge];
        } else if ([zeroRange isKindOfClass:[EXTZeroRangeTriple class]]) {
            EXTZeroRangeTriple *zrTriple = (EXTZeroRangeTriple*)zeroRange;
            return [NSString stringWithFormat:@"(%d, %d, %d) → (%d, %d, %d)",
                    zrTriple.leftEdge, zrTriple.bottomEdge, zrTriple.backEdge,
                    zrTriple.rightEdge, zrTriple.topEdge, zrTriple.frontEdge];
        } else
            return nil;
    } else
        return nil;
}

- (void)doubleClick:(id)sender {
    if ((self.tableView.selectedRow < 0) || (self.tableView.selectedRow >= self.zeroRanges.count))
        return;
    
    // initialize the pieces of the sheet.
    _activeZR = self.zeroRanges[self.tableView.selectedRow];
    if ([[_activeZR class] isSubclassOfClass:[EXTZeroRangeStrict class]])
        return;
    else if ([[_activeZR class] isSubclassOfClass:[EXTZeroRangePair class]]) {
        EXTZeroRangePair *zrPair = (EXTZeroRangePair*)_activeZR;
        self.leftEdge.integerValue = zrPair.leftEdge;
        self.rightEdge.integerValue = zrPair.rightEdge;
        self.topEdge.integerValue = zrPair.topEdge;
        self.bottomEdge.integerValue = zrPair.bottomEdge;
        
        self.frontEdge.stringValue = @"";
        self.backEdge.stringValue = @"";
        self.frontEdge.enabled = false;
        self.backEdge.enabled = false;
    } else if ([[_activeZR class] isSubclassOfClass:[EXTZeroRangeTriple class]]) {
        EXTZeroRangeTriple *zrTriple = (EXTZeroRangeTriple*)_activeZR;
        self.leftEdge.integerValue = zrTriple.leftEdge;
        self.rightEdge.integerValue = zrTriple.rightEdge;
        self.topEdge.integerValue = zrTriple.topEdge;
        self.bottomEdge.integerValue = zrTriple.bottomEdge;
        self.frontEdge.integerValue = zrTriple.frontEdge;
        self.backEdge.integerValue = zrTriple.backEdge;
        
        self.frontEdge.enabled = true;
        self.backEdge.enabled = true;
    } else
        return;
    
    // and display
    [self.popover showRelativeToRect:[self.tableView rectOfRow:self.tableView.selectedRow] ofView:self.tableView preferredEdge:NSMinXEdge];
    
    return;
}

- (void)popoverWillClose:(NSNotification *)notification {
    if ([[_activeZR class] isSubclassOfClass:[EXTZeroRangeStrict class]])
        return;
    else if ([[_activeZR class] isSubclassOfClass:[EXTZeroRangePair class]]) {
        EXTZeroRangePair *zrPair = (EXTZeroRangePair*)_activeZR;
        zrPair.leftEdge = self.leftEdge.integerValue;
        zrPair.rightEdge = self.rightEdge.integerValue;
        zrPair.topEdge = self.topEdge.integerValue;
        zrPair.bottomEdge = self.bottomEdge.integerValue;
    } else if ([[_activeZR class] isSubclassOfClass:[EXTZeroRangeTriple class]]) {
        EXTZeroRangeTriple *zrTriple = (EXTZeroRangeTriple*)_activeZR;
        zrTriple.leftEdge = self.leftEdge.integerValue;
        zrTriple.rightEdge = self.rightEdge.integerValue;
        zrTriple.topEdge = self.topEdge.integerValue;
        zrTriple.bottomEdge = self.bottomEdge.integerValue;
        zrTriple.backEdge = self.backEdge.integerValue;
        zrTriple.frontEdge = self.frontEdge.integerValue;
    } else
        return;
    
    [_tableView reloadData];
    
    return;
}

#pragma mark - EXTDocumentInspectorViewDelegate

- (void)documentWindowController:(EXTDocumentWindowController *)windowController
             didAddInspectorView:(NSView *)inspectorView {
    [self bind:@"sseq" toObject:windowController.document withKeyPath:@"sseq" options:nil];
    self.documentWindowController = windowController;
}

- (void)documentWindowController:(EXTDocumentWindowController *)windowController
         willRemoveInspectorView:(NSView *)inspectorView {
    [self unbind:@"sseq"];
    [self unbind:@"zeroRanges"];
    
    _sseq = nil;
    _documentWindowController = nil;
    _zeroRanges = nil;
}

- (void)setSseq:(EXTSpectralSequence *)sseq {
    _sseq = sseq;
    
    [self unbind:@"zeroRanges"];
    [self bind:@"zeroRanges" toObject:sseq withKeyPath:@"zeroRanges" options:nil];
    
    [_tableView reloadData];
}

- (EXTSpectralSequence*) sseq {
    return _sseq;
}

- (void)setZeroRanges:(NSArray *)zeroRanges {
    _zeroRanges = zeroRanges;
    [self.tableView reloadData];
}

- (NSArray *)zeroRanges {
    return _zeroRanges;
}

@end
