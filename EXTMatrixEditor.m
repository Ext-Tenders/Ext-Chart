//
//  EXTMatrixEditor.m
//  Ext Chart
//
//  Created by Eric Peterson on 8/17/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTMatrixEditor.h"
#import "MBTableGridHeaderView.h"

@interface EXTMatrixEditor () <MBTableGridDataSource, MBTableGridDelegate>

@end

@implementation EXTMatrixEditor

@synthesize representedObject;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        representedObject = nil;
        self.dataSource = self;
        self.delegate = self;

        [self _extResetRowHeaderToolTips];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rowHeaderViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:[self rowHeaderView]];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // don't do anything i wouldn't do.
    [super drawRect:dirtyRect];
}

- (NSUInteger)numberOfColumnsInTableGrid:(MBTableGrid *)aTableGrid {
    return representedObject ? representedObject.width : 0;
}

- (NSUInteger)numberOfRowsInTableGrid:(MBTableGrid *)aTableGrid {
    return representedObject ? representedObject.height : 0;
}

- (id)tableGrid:(MBTableGrid *)aTableGrid objectValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
    if (!representedObject)
        return nil;
    return [NSString stringWithFormat:@"%@",
                [representedObject.presentation[columnIndex]
                                                    objectAtIndex:rowIndex]];
}

- (void)tableGrid:(MBTableGrid *)aTableGrid setObjectValue:(id)anObject forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
    if (!representedObject)
        return;
    
    NSMutableArray *presentation = representedObject.presentation;
    NSMutableArray *column = presentation[columnIndex];
    NSInteger value = [anObject intValue];
    column[rowIndex] = @(value);
    
    return;
}

- (NSString *)tableGrid:(MBTableGrid *)aTableGrid
  headerStringForColumn:(NSUInteger)columnIndex {
    if ((!_columnNames) ||
        (columnIndex >= _columnNames.count))
        return [NSString stringWithFormat:@"%ld",(unsigned long)columnIndex];
    
    return _columnNames[columnIndex];
}

- (NSString *)tableGrid:(MBTableGrid *)aTableGrid
     headerStringForRow:(NSUInteger)rowIndex {
    if ((!_rowNames) ||
        (rowIndex >= _rowNames.count))
        return [NSString stringWithFormat:@"%ld",(unsigned long)rowIndex];
    
    return _rowNames[rowIndex];
}

- (NSColor *)tableGrid:(MBTableGrid *)aTableGrid backgroundColorForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
    return nil;
}

#pragma mark - NSToolTipOwner

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data {
    NSUInteger rowIndex = (NSUInteger)floor(point.y / 19.0 /* row height */);
    return [self tableGrid:self headerStringForRow:rowIndex];
}

- (void)_extResetRowHeaderToolTips {
    [[self rowHeaderView] removeAllToolTips];
    [[self rowHeaderView] addToolTipRect:[[self rowHeaderView] bounds] owner:self userData:NULL];
}

#pragma mark - Notifications

- (void)rowHeaderViewFrameDidChange:(NSNotification *)notification {
    [self _extResetRowHeaderToolTips];
}

@end
