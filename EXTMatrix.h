//
//  EXTMatrix.h
//  Ext Chart
//
//  Created by Eric Peterson on 3/16/13.
//  Copyright (c) 2013 HLProducts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EXTMatrix : NSObject
    {
        NSUInteger height, width;
        NSMutableArray *presentation;
    }

    @property(assign) NSUInteger height, width;
    @property(retain) NSMutableArray *presentation;

    +(EXTMatrix*) initWidth:(int)newWidth height:(int)newHeight;
    +(EXTMatrix*) matrixWidth:(int)newWidth height:(int)newHeight;

    // matrix operations
    +(EXTMatrix*) copyTranspose:(EXTMatrix*)input;
    +(EXTMatrix*) newMultiply:(EXTMatrix*)left by:(EXTMatrix*)right;
    -(EXTMatrix*) columnReduce;
    -(NSMutableArray*) kernel;
    -(NSMutableArray*) image;

    // debug operations
    -(void) log;

@end
