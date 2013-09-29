//
//  EXTZeroRangesInspector.m
//  Ext Chart
//
//  Created by Eric Peterson on 9/28/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTZeroRangesInspector.h"
#import "EXTDocumentWindowController.h"
#import "EXTSpectralSequence.h"

@interface EXTZeroRangesInspector () <NSTableViewDataSource, NSTableViewDelegate, NSPopoverDelegate, EXTDocumentInspectorViewDelegate>

@property IBOutlet NSPopover *popover;
@property IBOutlet NSForm *form;
@property IBOutlet NSTableView *tableView;
@property IBOutlet NSButton *addButton;
@property IBOutlet NSButton *deleteButton;
@property IBOutlet NSButton *dropdownMenu;

@property (weak) NSWindowController *documentWindowController;
@property (weak,nonatomic) EXTSpectralSequence *sseq;
@property (weak,nonatomic) NSArray *zeroRanges;

@end

@implementation EXTZeroRangesInspector
{
    EXTSpectralSequence *_sseq;
    NSArray *_zeroRanges;
}

- (id)init {
    return (self = [self initWithNibName:@"EXTZeroRangesInspector" bundle:nil]);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}



-(IBAction) deleteButtonPressed:(id)sender {
    
}

-(IBAction) addButtonPressed:(id)sender {
    
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
    } else if ([tableColumn.identifier isEqualToString:@"descriptor"]) {
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
    
    self.sseq = nil;
    self.documentWindowController = nil;
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
