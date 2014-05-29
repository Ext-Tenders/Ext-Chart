//
//  EXTMatrixEditor.h
//  Ext Chart
//
//  Created by Eric Peterson on 8/17/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "MBTableGrid/MBTableGrid.h"
#import "EXTMatrix.h"

@interface EXTMatrixEditor : MBTableGrid

@property (strong) EXTMatrix *representedObject;
@property (strong) NSArray *columnNames, *rowNames;

@end
