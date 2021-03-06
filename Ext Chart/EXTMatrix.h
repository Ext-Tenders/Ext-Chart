//
//  EXTMatrix.h
//  Ext Chart
//
//  Created by Eric Peterson on 3/16/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

@import Foundation;

@class EXTMatrix;
@class EXTTerm;

// this class models "partial definitions" of a matrix.  for instance, we
// have inference code that determines the differential on the image of a cup
// product map E_{p, q} (x) E_{p', q'} --> E_{p+p', q+q'}.  there's no reason
// for that map to be surjective, so instead this determines the behavior of the
// differential only on the subspace that is its image.
//
// such partial definitions are not trivial to stitch together, and so to do
// that successfully, we just record all the definitions we have, together.
@interface EXTPartialDefinition : NSObject <NSCoding, NSCopying>

@property (retain) EXTMatrix *inclusion;
@property (retain) EXTMatrix *action;
@property (assign,readonly) bool automaticallyGenerated;
@property (retain) NSString *description;

-(BOOL) isEqual:(id)object;
-(void) manuallyGenerated;

@end

@interface EXTMatrix : NSObject <NSCoding>

@property(assign) NSUInteger characteristic;
@property(assign) NSUInteger height, width;
@property(strong) NSMutableData *presentation;

+(EXTMatrix*) matrixWidth:(int)newWidth height:(int)newHeight;
-(EXTMatrix*) copy;

+(EXTMatrix*) hadamardProduct:(EXTMatrix*)left with:(EXTMatrix*)right;
+(NSArray*) hadamardVectors:(NSArray*)left with:(NSArray*)right;
+(EXTMatrix*) includeEvenlySpacedBasis:(int)startDim
                                endDim:(int)endDim
                                offset:(int)offset
                               spacing:(int)spacing;

// matrix operations
+(EXTMatrix*) copyTranspose:(EXTMatrix*)input;
+(EXTMatrix*) newMultiply:(EXTMatrix*)left by:(EXTMatrix*)right;
+(EXTMatrix*) identity:(int)width;
/// produces the inverse to an invertible matrix
-(EXTMatrix*) invert;
/// produces a right-inverse to an onto matrix
-(EXTMatrix*) invertOntoMap;
-(EXTMatrix*) columnReduce;
-(EXTMatrix*) modularReduction;
-(EXTMatrix*) kernel;
-(EXTMatrix*) image;
-(NSMutableArray*) actOn:(NSArray*)vector;
-(int) rank;
-(EXTMatrix*) scale:(int)scalar;
+(EXTMatrix*) sum:(EXTMatrix*)a with:(EXTMatrix*)b;

/// produces an (n + n') x (m + m') from A of type n x m and B of type n' x m'
+(EXTMatrix*) directSum:(EXTMatrix*)a with:(EXTMatrix*)b;
/// produces an n x (m + m') from A of type n x m and B of type n x m'
+(EXTMatrix*) directSumWithCommonTargetA:(EXTMatrix*)a B:(EXTMatrix*)b;

// @[left inclusion, right inclusion]
+(NSArray*) formIntersection:(EXTMatrix*)left with:(EXTMatrix*)right;

+(EXTMatrix*) assemblePresentation:(NSMutableArray*)partialDefinitions
                   sourceDimension:(int)sourceDimension
                   targetDimension:(int)targetDimension;

+(NSDictionary*) findOrdersOf:(EXTMatrix*)B in:(EXTMatrix*)Z;
+(int) rankOfMap:(EXTMatrix*)map intoQuotientByTheInclusion:(EXTMatrix*)incl;

// TODO: this signature may not be optimal. do we really want to introduce
// a dependancy on EXTTerm?
-(NSDictionary*) homologyToHomologyKeysFrom:(EXTTerm*)source
                                         to:(EXTTerm*)target
                                     onPage:(int)page;

@end
