//
//  EXTMatrixEditor.m
//  Ext Chart
//
//  Created by Eric Peterson on 8/17/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTMatrixEditor.h"

@interface EXTMatrixEditor () <MBTableGridDataSource, MBTableGridDelegate>

@end

@implementation EXTMatrixEditor {
    EXTMatrix *_representedObject;
}

- (EXTMatrix *)representedObject {
    return _representedObject;
}

- (void)setRepresentedObject:(EXTMatrix *)representedObject {
    _representedObject = representedObject;
    [self reloadData];
    return;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _representedObject = nil;
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // don't do anything i wouldn't do.
    [super drawRect:dirtyRect];
}

- (NSUInteger)numberOfColumnsInTableGrid:(MBTableGrid *)aTableGrid {
    return _representedObject ? _representedObject.width : 0;
}

- (NSUInteger)numberOfRowsInTableGrid:(MBTableGrid *)aTableGrid {
    return _representedObject ? _representedObject.height : 0;
}

- (id)tableGrid:(MBTableGrid *)aTableGrid objectValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
    if (!_representedObject)
        return nil;
    return [NSString stringWithFormat:@"%@",
                [_representedObject.presentation[columnIndex]
                                                    objectAtIndex:rowIndex]];
}

- (void)tableGrid:(MBTableGrid *)aTableGrid setObjectValue:(id)anObject forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
    DLog(@"Haven't implemented matrix editing yet.");
    return;
}

- (NSString *)tableGrid:(MBTableGrid *)aTableGrid
  headerStringForColumn:(NSUInteger)columnIndex {
    if ((!_columnNames) ||
        (_columnNames.count >= columnIndex))
        return [NSString stringWithFormat:@"%ld",(unsigned long)columnIndex];
    
    return _columnNames[columnIndex];
}

- (NSString *)tableGrid:(MBTableGrid *)aTableGrid
     headerStringForRow:(NSUInteger)rowIndex {
    if ((!_rowNames) ||
        (_rowNames.count >= rowIndex))
        return [NSString stringWithFormat:@"%ld",(unsigned long)rowIndex];
    
    return _rowNames[rowIndex];
}

@end
