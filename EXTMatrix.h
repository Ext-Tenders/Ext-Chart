//
//  EXTMatrix.h
//  Ext Chart
//
//  Created by Eric Peterson on 3/16/13.
//  Copyright (c) 2013 HLProducts. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EXTMatrix;

// this class models "partial definitions" of a matrix.  for instance, we
// have inference code that determines the differential on the image of a cup
// product map E_{p, q} (x) E_{p', q'} --> E_{p+p', q+q'}.  there's no reason
// for that map to be surjective, so instead this determines the behavior of the
// differential only on the subspace that is its image.
//
// such partial definitions are not trivial to stitch together, and so to do
// that successfully, we just record all the definitions we have, together.
@interface EXTPartialDefinition : NSObject {
    EXTMatrix *inclusion;
    EXTMatrix *differential;
    bool automaticallyGenerated;
}

@property (retain) EXTMatrix *inclusion;
@property (retain) EXTMatrix *differential;
@property (assign) bool automaticallyGenerated;

@end



@interface EXTMatrix : NSObject
    {
        NSUInteger height, width;
        NSMutableArray *presentation;
    }

    @property(assign) NSUInteger height, width;
    @property(strong) NSMutableArray *presentation;

    +(EXTMatrix*) initWidth:(int)newWidth height:(int)newHeight;
    +(EXTMatrix*) matrixWidth:(int)newWidth height:(int)newHeight;
    -(EXTMatrix*) copy;

    // matrix operations
    +(EXTMatrix*) copyTranspose:(EXTMatrix*)input;
    +(EXTMatrix*) newMultiply:(EXTMatrix*)left by:(EXTMatrix*)right;
    +(EXTMatrix*) identity:(int)width;
    -(EXTMatrix*) invert;
    -(EXTMatrix*) columnReduce;
    -(void) modularReduction;
    -(NSMutableArray*) kernel;
    -(NSMutableArray*) image;
    -(NSMutableArray*) actOn:(NSMutableArray*)vector;
    -(int) rank;

    +(EXTMatrix*) assemblePresentation:(NSMutableArray*)partialDefinitions
                       sourceDimension:(int)sourceDimension
                       targetDimension:(int)targetDimension;

    // debug operations
    -(void) log;

@end
