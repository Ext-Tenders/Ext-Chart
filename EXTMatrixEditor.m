//
//  EXTMatrixEditor.m
//  Ext Chart
//
//  Created by Eric Peterson on 8/17/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTMatrixEditor.h"
#import "../MBTableGrid/MBTableGridHeaderView.h"
#import "../MBTableGrid/MBTableGridCell.h"
#import <objc/runtime.h>


@interface EXTMatrixEditor () <MBTableGridDataSource, MBTableGridDelegate>

@property (nonatomic, weak) id<EXTMatrixEditorDelegate> externalDelegate;

@end


// We use a custom cell so that cell contents are selected whenever the cell is edited
@interface EXTMatrixCell : MBTableGridCell
@end


@implementation EXTMatrixEditor

@synthesize representedObject, readonly;

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        representedObject = nil;
        self.dataSource = self;
        [super setDelegate:self];
        self.readonly = false;

        EXTMatrixCell *defaultCell = [EXTMatrixCell new];
        defaultCell.bordered = YES;
        defaultCell.scrollable = YES;
		defaultCell.lineBreakMode = NSLineBreakByTruncatingTail;
        self.cell = defaultCell;

        [self _extResetRowHeaderToolTips];
        [[NSNotificationCenter defaultCenter]
                addObserver:self
                   selector:@selector(rowHeaderViewFrameDidChange:)
                       name:NSViewFrameDidChangeNotification
                     object:[self rowHeaderView]];
    }
    
    return self;
}

- (void)setDelegate:(id<EXTMatrixEditorDelegate>)externalDelegate {
    _externalDelegate = externalDelegate;
    
    return;
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
    if (!representedObject || readonly)
        return;
    
    NSMutableArray *presentation = representedObject.presentation;
    NSMutableArray *column = presentation[columnIndex];
    NSInteger value = [anObject intValue];
    column[rowIndex] = @(value);
    
    if ([self.externalDelegate respondsToSelector:@selector(matrixEditorDidUpdate)])
        [self.externalDelegate matrixEditorDidUpdate];
    
    return;
}

- (NSString *)tableGrid:(MBTableGrid *)aTableGrid
  headerStringForColumn:(NSUInteger)columnIndex {
    if ((!_columnNames) ||
        (columnIndex >= _columnNames.count))
        return [NSString stringWithFormat:@"%ld",(unsigned long)columnIndex+1];
    
    return _columnNames[columnIndex];
}

- (NSString *)tableGrid:(MBTableGrid *)aTableGrid
     headerStringForRow:(NSUInteger)rowIndex {
    if ((!_rowNames) ||
        (rowIndex >= _rowNames.count))
        return [NSString stringWithFormat:@"%ld",(unsigned long)rowIndex+1];
    
    return _rowNames[rowIndex];
}

- (NSColor *)tableGrid:(MBTableGrid *)aTableGrid backgroundColorForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
    return nil;
}

#pragma mark - NSToolTipOwner

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data {
    NSUInteger rowIndex = (NSUInteger)data;
    return [self tableGrid:self headerStringForRow:rowIndex];
}

- (void)_extResetRowHeaderToolTips {
    [rowHeaderView removeAllToolTips];

    for (NSUInteger rowIndex = 0; rowIndex < representedObject.height; rowIndex++)
        [rowHeaderView addToolTipRect:[rowHeaderView headerRectOfRow:rowIndex] owner:self userData:(void *)rowIndex];
}

#pragma mark - Notifications

- (void)rowHeaderViewFrameDidChange:(NSNotification *)notification {
    [self _extResetRowHeaderToolTips];
}

#pragma mark - delegate forwarding routines

// see https://gist.github.com/tangphillip/818bdd6d916b62f607b7
+ (BOOL)isInstanceMethodSelector:(SEL)selector inProtocol:(Protocol *)protocol {
    struct objc_method_description requiredMethod = protocol_getMethodDescription(protocol, selector, YES, YES);
    struct objc_method_description optionalMethod = protocol_getMethodDescription(protocol, selector,  NO, YES);
    
    return (requiredMethod.name != NULL || optionalMethod.name != NULL);
}

- (id)forwardingTargetForSelector:(SEL)selector {
    BOOL isDelegateSelector = [[self class] isInstanceMethodSelector:selector
                                                          inProtocol:@protocol(EXTMatrixEditorDelegate)];
    if (isDelegateSelector && [self.externalDelegate respondsToSelector:selector]) {
        return self.externalDelegate;
    }
    
    return [super forwardingTargetForSelector:selector];
}

- (BOOL)respondsToSelector:(SEL)selector {
    BOOL isDelegateSelector = [[self class] isInstanceMethodSelector:selector
                                                          inProtocol:@protocol(EXTMatrixEditorDelegate)];
    if (isDelegateSelector && [self.externalDelegate respondsToSelector:selector]) {
        return YES;
    }
    
    return [super respondsToSelector:selector];
}

@end


@implementation EXTMatrixCell

- (void)editWithFrame:(NSRect)cellFrame inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)delegateObj event:(NSEvent *)event {
    [super editWithFrame:cellFrame inView:controlView editor:textObj delegate:delegateObj event:event];
    [textObj setSelectedRange:(NSRange){0, textObj.string.length}];
}

@end
