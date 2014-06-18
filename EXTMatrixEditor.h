//
//  EXTMatrixEditor.h
//  Ext Chart
//
//  Created by Eric Peterson on 8/17/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "MBTableGrid/MBTableGrid.h"
#import "EXTMatrix.h"

@protocol EXTMatrixEditorDelegate <NSObject, MBTableGridDelegate>

-(void)matrixEditorDidUpdate;

@end

@interface EXTMatrixEditor : MBTableGrid

@property (weak,nonatomic) NSObject<EXTMatrixEditorDelegate>* delegate;

@property (strong) EXTMatrix *representedObject;
@property (strong) NSArray *columnNames, *rowNames;
@property (assign) bool readonly;

@end
