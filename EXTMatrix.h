//
//  EXTMatrix.h
//  Ext Chart
//
//  Created by Eric Peterson on 3/16/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
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
@interface EXTPartialDefinition : NSObject <NSCoding>

@property (retain) EXTMatrix *inclusion;
@property (retain) EXTMatrix *action;
@property (assign,readonly) bool automaticallyGenerated;
@property (retain) NSString *description;

-(BOOL) isEqual:(id)object;
-(void) manuallyGenerated;

@end



@interface EXTMatrix : NSObject <NSCoding> {
    NSUInteger height, width;
    NSMutableArray *presentation;
}

@property(assign) NSUInteger height, width;
@property(strong) NSMutableArray *presentation;

+(EXTMatrix*) matrixWidth:(int)newWidth height:(int)newHeight;
-(EXTMatrix*) copy;

+(EXTMatrix*) hadamardProduct:(EXTMatrix*)left with:(EXTMatrix*)right;
+(EXTMatrix*) includeEvenlySpacedBasis:(int)startDim
                                endDim:(int)endDim
                                offset:(int)offset
                               spacing:(int)spacing;

// matrix operations
+(EXTMatrix*) copyTranspose:(EXTMatrix*)input;
+(EXTMatrix*) newMultiply:(EXTMatrix*)left by:(EXTMatrix*)right;
+(EXTMatrix*) identity:(int)width;
-(EXTMatrix*) invert;
-(EXTMatrix*) columnReduce;
-(void) modularReduction;
-(NSMutableArray*) kernel;
-(NSMutableArray*) image;
-(NSMutableArray*) actOn:(NSArray*)vector;
-(int) rank;
-(EXTMatrix*) scale:(int)scalar;
+(EXTMatrix*) sum:(EXTMatrix*)a with:(EXTMatrix*)b;

// @[left inclusion, right inclusion]
+(NSArray*) formIntersection:(EXTMatrix*)left with:(EXTMatrix*)right;

+(EXTMatrix*) assemblePresentation:(NSMutableArray*)partialDefinitions
                   sourceDimension:(int)sourceDimension
                   targetDimension:(int)targetDimension;
+(NSArray*) assemblePresentationAndOptimize:(NSMutableArray*)partialDefinitions
                            sourceDimension:(int)sourceDimension
                            targetDimension:(int)targetDimension;

+(NSDictionary*) findOrdersOf:(EXTMatrix*)B in:(EXTMatrix*)Z;

// debug operations
-(void) log;

@end
