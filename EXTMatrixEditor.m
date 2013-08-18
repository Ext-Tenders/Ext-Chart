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

@implementation EXTMatrixEditor

@synthesize representedObject;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        representedObject = nil;
        self.dataSource = self;
        self.delegate = self;
    }
    
    return self;
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
    
    [representedObject.presentation[columnIndex] setObject:@([anObject intValue]) atIndex:rowIndex];
    
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

@end
