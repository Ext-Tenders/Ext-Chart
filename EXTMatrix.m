//
//  EXTMatrix.m
//  Ext Chart
//
//  Created by Eric Peterson on 3/16/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EXTMatrix.h"

// little class to keep track of partial subdefinitions of a parent matrix
@implementation EXTPartialDefinition {
    bool automaticallyGenerated;
}

@synthesize inclusion;
@synthesize action;
@synthesize description;

-(bool) automaticallyGenerated {
    return automaticallyGenerated;
}

-(EXTPartialDefinition*) init {
    if (!(self = [super init])) return nil;
    
    // we don't keep track of enough information about dimensions to make the
    // appropriate initialization calls to EXTMatrix factories.
    inclusion = nil;
    action = nil;
    automaticallyGenerated = true;
    description = nil;
    
    return self;
}

-(BOOL) isEqual:(id)object {
    if ([object class] != [EXTPartialDefinition class])
        return false;
    
    EXTPartialDefinition *target = (EXTPartialDefinition*)object;
    
    return ([self.action isEqual:target.action] &&
            [self.inclusion isEqual:target.inclusion]);
}

-(void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:inclusion forKey:@"inclusion"];
    [aCoder encodeObject:action forKey:@"action"];
    [aCoder encodeBool:automaticallyGenerated forKey:@"automaticallyGenerated"];
    [aCoder encodeObject:description forKey:@"description"];
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        inclusion = [aDecoder decodeObjectForKey:@"inclusion"];
        action = [aDecoder decodeObjectForKey:@"action"];
        automaticallyGenerated =
                        [aDecoder decodeBoolForKey:@"automaticallyGenerated"];
        description = [aDecoder decodeObjectForKey:@"description"];
    }
    
    return self;
}

-(void) manuallyGenerated {
    automaticallyGenerated = false;
}

@end




@implementation EXTMatrix

// XXX: somehow change the presentation getter to recompute the presentation off
// of the partial definitions --- but ideally not every time we need to access
// the presentation, just when it's somehow "dirty"...
@synthesize characteristic;
@synthesize height, width;
@synthesize presentation;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        characteristic = [aDecoder decodeIntForKey:@"characteristic"];
        height = [aDecoder decodeIntForKey:@"height"];
        width = [aDecoder decodeIntForKey:@"width"];
        presentation = [aDecoder decodeObjectForKey:@"presentation"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInt:characteristic forKey:@"characteristic"];
    [aCoder encodeInt:height forKey:@"height"];
    [aCoder encodeInt:width forKey:@"width"];
    [aCoder encodeObject:presentation forKey:@"presentation"];
}

-(BOOL) isEqual:(id)object {
    if ([object class] != [EXTMatrix class])
        return false;
    
    EXTMatrix *mat = (EXTMatrix*)object;
    
    if ((mat.width != self.width) ||
        (mat.height != self.height) ||
        (mat.characteristic != self.characteristic))
        return false;
    
    for (int i = 0; i < self.width; i++)
        for (int j = 0; j < self.height; j++) {
            int s = [((NSMutableArray*)self.presentation[i])[j] intValue],
                m = [((NSMutableArray*)mat.presentation[i])[j] intValue];
            
            if (s >= self.characteristic && self.characteristic != 0) {
                s %= self.characteristic;
                self.presentation[i][j] = @(s);
            }
            
            if (m >= self.characteristic && self.characteristic != 0) {
                m %= self.characteristic;
                mat.presentation[i][j] = @(m);
            }
            
            if (s != m)
                return false;
        }
    
    return true;
}

// initializes an EXTMatrix object and allocates all the NSMutableArrays
// used in the presentation.
+(EXTMatrix*) matrixWidth:(int)newWidth height:(int)newHeight {
    EXTMatrix *obj = [EXTMatrix new];
    
    // set the basic properties
    [obj setHeight:newHeight];
    [obj setWidth:newWidth];
    [obj setCharacteristic:0];
    
    // allocate the matrix
    NSMutableArray *matrix = [NSMutableArray arrayWithCapacity:obj.width];
    for (int j = 0; j < obj.width; j++) {
        NSMutableArray *column = [NSMutableArray arrayWithCapacity:obj.height];
        for (int i = 0; i < obj.height; i++)
            [column setObject:@(0) atIndexedSubscript:i];
        [matrix setObject:column atIndexedSubscript:j];
    }
    
    // ... and store the matrix.
    obj.presentation = matrix;
    
    return obj;
}

+(EXTMatrix*) hadamardProduct:(EXTMatrix*)left with:(EXTMatrix*)right {
    EXTMatrix *ret = [EXTMatrix matrixWidth:(left.width*right.width)
                                     height:(left.height*right.height)];
    if (left.characteristic == right.characteristic)
        ret.characteristic = left.characteristic;
    else {
        int a = left.characteristic,
            b = right.characteristic,
            gcd = 0;
        
        EXTComputeGCD(&a, &b, &gcd, NULL, NULL);
        
        ret.characteristic = gcd;
    }
    
    for (int i = 0; i < left.width; i++) {
        NSMutableArray *leftcol = left.presentation[i];
        for (int j = 0; j < right.width; j++) {
            NSMutableArray *rightcol = right.presentation[j],
                             *retcol = ret.presentation[i*right.width+j];
            for (int k = 0; k < left.height; k++) {
                for (int l = 0; l < right.height; l++) {
                    int val = [leftcol[k] intValue] * [rightcol[l] intValue];
                    if (ret.characteristic != 0)
                        val %= ret.characteristic;
                    retcol[k*right.height+l] = @(val);
                }
            }
        }
    }
    
    return ret;
}

+(EXTMatrix*) includeEvenlySpacedBasis:(int)startDim
                                endDim:(int)endDim
                                offset:(int)offset
                               spacing:(int)spacing {
    EXTMatrix *ret = [EXTMatrix matrixWidth:startDim height:endDim];
    
    // poke some 1s into the right places :)
    for (int i = 0; i < startDim; i++)
        ((NSMutableArray*)ret.presentation[offset+spacing*i])[i] = @1;
    
    return ret;
}

// allocates and initializes a new matrix 
+(EXTMatrix*) copyTranspose:(EXTMatrix *)input {
    EXTMatrix *ret = [EXTMatrix matrixWidth:input.height
                                     height:input.width];
    ret.characteristic = input.characteristic;
    
    for (int i = 0; i < [input height]; i++) {
        NSMutableArray *newColumn =
            [NSMutableArray arrayWithCapacity:input.height];
        
        for (int j = 0; j < [input width]; j++) {
            // read off the subscripts in the inverse order
            newColumn[j] = input.presentation[j][i];
        }
        
        [ret.presentation setObject:newColumn atIndexedSubscript:i];
    }
    
    return ret;
}

// replaces all the elements of a matrix with their reductions mod char
-(EXTMatrix*) modularReduction {
    if (self.characteristic == 0)
        return self;
    
    for (int i = 0; i < width; i++) {
        NSMutableArray *column = [presentation objectAtIndex:i];
        
        for (int j = 0; j < height; j++)
            column[j] = @([column[j] intValue] % self.characteristic);
    }
    
    return self;
}

// performs a deep copy of the matrix
-(EXTMatrix*) copy {
    EXTMatrix *copy = [EXTMatrix matrixWidth:width height:height];
    copy.characteristic = self.characteristic;
    
    for (int i = 0; i < width; i++)
        for (int j = 0; j < height; j++) {
            NSNumber *num = ((NSArray*)presentation[i])[j];
            ((NSMutableArray*)copy.presentation[i])[j] = num;
        }
    
    return copy;
}

-(NSArray*) columnReduceWithRightFactor {
    EXTMatrix *ret = [self copy],
              *rightFactor = [EXTMatrix identity:self.width];
    NSMutableArray *usedColumns = [NSMutableArray array];
    for (int i = 0; i < width; i++)
        usedColumns[i] = @(false);
    
    for (int pivotRow = 0, pivotColumn = 0;
         pivotRow < height;
         pivotRow++) {
        
        int j, firstNonzeroEntry = -1;
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:width],
        *rowToBezout = [NSMutableArray arrayWithCapacity:width];
        
        // save this row for analysis.
        for (int k = 0; k < width; k++) {
            row[k] = ret.presentation[k][pivotRow];
            
            if ([usedColumns[k] intValue])
                rowToBezout[k] = @0;
            else
                rowToBezout[k] = ret.presentation[k][pivotRow];
            
            if (firstNonzeroEntry == -1 && [row[k] intValue] != 0)
                firstNonzeroEntry = k;
        }
        
        if (firstNonzeroEntry == -1)
            continue;
        
        // compute the bezout vector for this row.
        NSMutableArray *bezout =
        [NSMutableArray arrayWithCapacity:rowToBezout.count];
        int gcd = [rowToBezout[firstNonzeroEntry] intValue];
        for (int k = 0; k < firstNonzeroEntry; k++)
            bezout[k] = @0;
        bezout[firstNonzeroEntry] = @1;
        
        for (NSInteger index = firstNonzeroEntry + 1;
             index < row.count;
             index++) {
            
            // don't look at this column if it's already been used.
            if ([usedColumns[index] intValue]) {
                bezout[index] = @0;
                continue;
            }
            
            if ([row[index] intValue] == 0) {
                bezout[index] = @0;
                continue;
            }
            
            int a = gcd,
                b = [row[index] intValue],
                newGcd = 0,
                r = 0,
                s = 0;
            
            EXTComputeGCD(&a, &b, &newGcd, &r, &s);
            
            if (abs(gcd) == abs(newGcd)) {
                bezout[index] = @0;
                continue;
            }
            
            gcd = newGcd;
            bezout[index] = @(s);
            for (NSInteger j = 0; j < index; j++)
                bezout[j] = @([bezout[j] intValue] * r);
        }
        
        // find the first nonzero entry in this row, right of where we're at
        for (j = 0; j < width; j++) {
            if ([usedColumns[j] intValue])
                continue;
            if (0 != [bezout[j] intValue])
                break;
        }
        
        // if we found a nonzero entry, then this is the new pivot column.
        // if we didn't, then we should skip this row entirely.
        if (j == width)
            continue;
        else {
            pivotColumn = j;
            usedColumns[j] = @(true);
        }
        
        // if we've made it here, then we have a new pivot location, and we're
        // tasked with clearing the rest of the row of nonzero entries.
        //
        // start by replacing this column with the Bezout-weighted sum of the
        // old columns.
        NSArray *newColumn = [ret actOn:bezout];
        ret.presentation[pivotColumn] =
                                    [NSMutableArray arrayWithArray:newColumn];
        EXTMatrix *rightmostFactor = [EXTMatrix identity:self.width];
        rightmostFactor.presentation[pivotColumn] = bezout;
        
        // then iterate through the other columns...
        for (j = 0; j < width; j++) {
            NSMutableArray *workingColumn = ret.presentation[j],
                           *factorColumn = rightmostFactor.presentation[j];
            
            // skip the column if this row is already zeroed out.
            if ([workingColumn[pivotRow] intValue] == 0)
                continue;
            
            // XXX: I think that this is lethal behavior; we can't use this to
            // run -invert if we don't do this part of the factorization too.
            //
            // also skip the column if it's already been used & so is stuck.
            //if ([usedColumns[j] intValue])
            //    continue;
            
            // skip the present pivot column too.
            if (pivotColumn == j)
                continue;
            
            // NOTE: this is *always* an integer, because the pivotRow entry of
            // our pivotColumn now contains the gcd of all the pivotRow values.
            int factor = [workingColumn[pivotRow] intValue] /
            [newColumn[pivotRow] intValue];
            
            // ... and for each entry in this column, subtract.
            for (int i = 0; i < height; i++) {
                workingColumn[i] = @([workingColumn[i] intValue] -
                                     factor * [newColumn[i] intValue]);
            }
            
            for (int i = 0; i < width; i++) {
                factorColumn[i] = @([factorColumn[i] intValue] -
                                     factor * [bezout[i] intValue]);
            }
        }
        
        // if necessary, put the matrix back in its modular equivalence class.
        [ret modularReduction];
        
        rightFactor = [EXTMatrix newMultiply:rightFactor by:rightmostFactor];
    }
    
    return @[ret, rightFactor];
}

// runs gaussian column reduction on a matrix over Z.  useful for finding a
// presentation of the image of the matrix.
-(EXTMatrix*) columnReduce {
    return (EXTMatrix*)self.columnReduceWithRightFactor[0];
}

// returns a basis for the kernel of a matrix
-(NSMutableArray*) kernel {
    // vertically augment the matrix by an identity matrix
    EXTMatrix *augmentedMatrix = [self copy];
    [augmentedMatrix setHeight:(self.height + self.width)];
    
    for (int i = 0; i < self.width; i++) {
        NSMutableArray *column = augmentedMatrix.presentation[i];
        for (int j = 0; j < self.width; j++) {
            if (i == j)
                [column addObject:@(1)];
            else
                [column addObject:@(0)];
        }
    }
    
    // column-reduce the augmented matrix
    EXTMatrix *reducedMatrix = [augmentedMatrix columnReduce];
    
    // read off the augmented columns corresponding to zero columns in the orig
    NSMutableArray *ret = [NSMutableArray array];
    
    for (int i = 0; i < reducedMatrix.width; i++) {
        NSMutableArray *augmentedColumn = reducedMatrix.presentation[i];
        
        // test to see if the original column is full of zeroes
        bool skipme = false;
        for (int j = 0; j < self.height; j++)
            if ([[augmentedColumn objectAtIndex:j] intValue] != 0)
                skipme = true;
        if (skipme)   // if we found nonzero entries...
            continue; // ... skip this column.
        
        // otherwise, strip to the augmented portion
        NSArray *strippedColumn =
            [augmentedColumn subarrayWithRange:NSMakeRange(self.height,
                                                           self.width)];
        [ret addObject:[NSMutableArray arrayWithArray:strippedColumn]];
    }
    
    // that's a basis for the kernel!
    return ret;
}

// returns a basis for the image of a matrix
-(NSMutableArray*) image {
    EXTMatrix *reduced = [self columnReduce];
    NSMutableArray *ret = [NSMutableArray array];
    
    // iterate through the columns
    for (int i = 0; i < [reduced width]; i++) {
        NSMutableArray *column = [[reduced presentation] objectAtIndex:i];
        
        // test to see if the column is not all zeroes
        bool skipit = true;
        for (int j = 0; j < [column count]; j++)
            if ([[column objectAtIndex:j] intValue] != 0)
                skipit = false;
        
        if (skipit)   // it's all zeroes...
            continue; // so skip it.
        
        // and, if it's not all zeroes, we should add it to the collection.
        // NOTE: it's important that we actually return a column from the
        // original matrix.  this is used elsewhere.
        //[ret addObject:self.presentation[i]];
        [ret addObject:reduced.presentation[i]];
    }
    
    return ret;
}

// returns the product of two matrices.
+(EXTMatrix*) newMultiply:(EXTMatrix*)left by:(EXTMatrix*)right {
    if (left.width != right.height)
        NSLog(@"Mismatched multiplication.");
    
    EXTMatrix *product = [EXTMatrix matrixWidth:[right width]
                                         height:[left height]];
    {
        int a = left.characteristic,
            b = right.characteristic,
            gcd = 0;
        
        EXTComputeGCD(&a, &b, &gcd, NULL, NULL);
        
        product.characteristic = gcd;
    }
    
    for (int k = 0; k < [right width]; k++) {
        NSMutableArray *rightColumn = [[right presentation] objectAtIndex:k],
                       *column = [NSMutableArray arrayWithCapacity:left.height];
        for (int i = 0; i < [left height]; i++) {
            int total = 0;
            
            for (int j = 0; j < [left width]; j++)
                total += [rightColumn[j] intValue] *
                         [left.presentation[j][i] intValue];
            
            column[i] = @(total);
        }
        
        [[product presentation] setObject:column atIndexedSubscript:k];
    }
    
    [product modularReduction];
    
    return product;
}

// matrix acts on a vector from the left.
-(NSMutableArray*) actOn:(NSArray *)vector {
    EXTMatrix *tempMatrix = [EXTMatrix matrixWidth:1 height:vector.count];
    tempMatrix.characteristic = self.characteristic;
    
    [tempMatrix.presentation setObject:[NSMutableArray arrayWithArray:vector]
                    atIndexedSubscript:0];
    
    EXTMatrix *product = [EXTMatrix newMultiply:self by:tempMatrix];
    
    NSMutableArray *result = [product.presentation objectAtIndex:0];
    
    return result;
}

+(EXTMatrix*) identity:(int)width {
    EXTMatrix *ret = [EXTMatrix matrixWidth:width height:width];
    
    for (int i = 0; i < width; i++)
        [[ret.presentation objectAtIndex:i] setObject:@1 atIndexedSubscript:i];
    
    return ret;
}

-(EXTMatrix*) invert {
    if (height != width)
        return nil;
    
    // augment the matrix by the identity
    EXTMatrix *temp = [self copy];
    [temp setWidth:(self.width*2)];
    [temp.presentation addObjectsFromArray:
                                [[EXTMatrix identity:self.width] presentation]];
    
    // perform column reduction
    EXTMatrix *flip = [EXTMatrix copyTranspose:temp];
    [flip columnReduce];
    EXTMatrix *unflip = [EXTMatrix copyTranspose:flip];
    
    // peel off the inverse from the augmented portion
    // XXX: some kind of error checking would be nice
    EXTMatrix *ret = [EXTMatrix matrixWidth:self.width height:self.width];
    ret.characteristic = self.characteristic;
    for (int i = 0; i < self.width; i++) {
        ret.presentation[i] = unflip.presentation[self.width+i];
    }
    
    return ret;
}

-(int) rank {
    NSMutableArray *image = [self image];
    
    return image.count;
}

// returns a pair (EXTMatrix* presentation, NSMutableArray* partialDefinitions),
// where the right-hand term contains a minimal list of necessary partial def'ns
// used the generate this presentation.  good for paring these down.
+(EXTMatrix*) assemblePresentation:(NSMutableArray*)partialDefinitions
                   sourceDimension:(int)sourceDimension
                   targetDimension:(int)targetDimension {
    // first, make sure we're not going to bomb.
    if (partialDefinitions.count == 0)
        return [EXTMatrix matrixWidth:sourceDimension height:targetDimension];
    
    // then, get a characteristic
    int characteristic =
           ((EXTPartialDefinition*)partialDefinitions[0]).action.characteristic;
    for (EXTPartialDefinition *partial in partialDefinitions)
        if (characteristic != partial.action.characteristic ||
            characteristic != partial.inclusion.characteristic)
            EXTLog(@"Inequal characteristics in presentation assembly.");
    
    // we first need to assemble all the inclusion image vectors into one
    // massive array.
    NSMutableArray *imageVectors = [NSMutableArray array], // array of vectors
        *imageParents = [NSMutableArray array], // def'n indices they belong to
        *imageIndices = [NSMutableArray array]; // column indices they belong to
    
    for (int i = 0; i < partialDefinitions.count; i++) {
        EXTPartialDefinition *workingPartial = partialDefinitions[i];
        NSMutableArray *workingVectors = workingPartial.inclusion.presentation;
        for (int j = 0; j < workingVectors.count; j++) {
            [imageVectors addObject:workingVectors[j]];
            [imageParents addObject:@(i)];
            [imageIndices addObject:@(j)];
        }
    }
    
    // the point of doing that was to perform column reduction and find a
    // minimal spanning set for their image.
    EXTMatrix *enormousMat = [EXTMatrix matrixWidth:imageVectors.count
                                             height:sourceDimension];
    enormousMat.characteristic = characteristic;
    enormousMat.presentation = imageVectors;
    enormousMat = [enormousMat columnReduce];
    
    // from this, let's extract a *minimal* generating set for the image.  if
    // the inclusions are jointly of full rank, we'll need this for later
    // calculations.  if they aren't of full rank, we can use this to see that
    // and bail if necessary.
    NSMutableArray *minimalVectors = [NSMutableArray array],
                   *minimalParents = [NSMutableArray array],
                   *minimalIndices = [NSMutableArray array];
    
    for (int i = 0; i < enormousMat.width; i++) {
        bool isEmpty = true;
        
        for (int j = 0; j < enormousMat.height; j++)
            if ([enormousMat.presentation[i][j] intValue] != 0)
                isEmpty = false;
        
        // if this vector is inessential, it will have been eliminated by cef.
        if (isEmpty)
            continue;
        
        // if it's essential, we should add it. :)
        [minimalVectors addObject:imageVectors[i]];
        [minimalParents addObject:imageParents[i]];
        [minimalIndices addObject:imageIndices[i]];
    }
    
    // we want to extend this basis of the cycle groups to a basis of the entire
    // E_1 term.  start by augmenting to a matrix containing a definite surplus
    // of basis vectors.
    NSMutableArray *augmentedVectors =
                                [NSMutableArray arrayWithArray:minimalVectors];
    for (int i = 0; i < sourceDimension; i++) {
        NSMutableArray *en = [NSMutableArray array];
        for (int j = 0; j < sourceDimension; j++) {
            if (i == j) {
                [en addObject:@1];
            } else {
                [en addObject:@0];
            }
        }
        
        [augmentedVectors addObject:en];
    }
    
    // then, column reduce it.  the vectors that survive will be our full basis.
    EXTMatrix *augmentedMat =
        [EXTMatrix matrixWidth:augmentedVectors.count height:sourceDimension];
    augmentedMat.presentation = augmentedVectors;
    augmentedMat.characteristic = characteristic;
    EXTMatrix *reducedMat = [augmentedMat columnReduce];
    NSMutableArray *reducedVectors = reducedMat.presentation;
    
    // having reduced it, we pull out the basis vectors we needed for extension
    for (int i = minimalVectors.count; i < reducedVectors.count; i++) {
        bool needThisOne = false;
        for (int j = 0; j < [reducedVectors[i] count]; j++) {
            if (![[reducedVectors[i] objectAtIndex:j] isEqual:@0])
                needThisOne = true;
        }
        
        if (needThisOne)
            [minimalVectors addObject:augmentedVectors[i]];
    }
    
    if (minimalVectors.count == 0) {
        EXTMatrix *ret = [EXTMatrix matrixWidth:sourceDimension height:targetDimension];
        ret.characteristic = characteristic;
        return ret;
    }
    
    // and so here's our basis matrix.
    EXTMatrix *basisMatrix =
        [EXTMatrix matrixWidth:minimalVectors.count
                        height:[minimalVectors[0] count]];
    basisMatrix.characteristic = characteristic;
    basisMatrix.presentation = minimalVectors;
    
    // now, we construct a matrix presenting the differential in this basis.
    // this is where the partial definitions actually get used.
    EXTMatrix *differentialInCoordinates =
            [EXTMatrix matrixWidth:basisMatrix.width height:targetDimension];
    differentialInCoordinates.characteristic = characteristic;
    for (int i = 0; i < basisMatrix.width; i++) {
        // if we're in the range of partially determined stuff, use the def'ns
        if (i < minimalParents.count) {
            EXTPartialDefinition *pdiffl =
                partialDefinitions[[minimalParents[i] intValue]];
            EXTMatrix *diffl = [pdiffl action];
            differentialInCoordinates.presentation[i] =
                diffl.presentation[[minimalIndices[i] intValue]];
        } else {
            // otherwise, extend by zero.
            NSMutableArray *workingColumn = [NSMutableArray array];
            
            for (int j = 0; j < targetDimension; j++)
                workingColumn[j] = @0;
            
            differentialInCoordinates.presentation[i] = workingColumn;
        }
    }
    
    // finally, we need to put these matrices together to build a presentation
    // of the differential in the standard basis.  this is simple: just invert
    // and multiply. :)
    EXTMatrix *basisConversion = [basisMatrix invert];
    EXTMatrix *stdDifferential =
        [EXTMatrix newMultiply:differentialInCoordinates by:basisConversion];
    
    // finally, all our hard work done, we jump back.
    return stdDifferential;
}

// returns a scaled matrix
-(EXTMatrix*) scale:(int)scalar {
    EXTMatrix *ret = [self copy];
    
    for (int i = 0; i < ret.presentation.count; i++) {
        NSMutableArray *col = ret.presentation[i];
        for (int j = 0; j < col.count; j++)
            col[j] = @(scalar * [col[j] intValue]);
    }
    
    [ret modularReduction];
    
    return ret;
}

// given a cospan A --> C <-- B, this routine forms the pullback span.
+(NSArray*) formIntersection:(EXTMatrix*)left with:(EXTMatrix*)right {
    // perform cleanup to put us in a good state.
    [left modularReduction];
    [right modularReduction];
    
    // form the matrix [P, -Q]
    EXTMatrix *sum = [EXTMatrix matrixWidth:(left.width + right.width)
                                     height:left.height];
    sum.presentation = [NSMutableArray arrayWithArray:left.presentation];
    [sum.presentation addObjectsFromArray:[right scale:(-1)].presentation];
    
    // the nullspace of [P, -Q] is a vertical sum [I; J] of the two inclusions
    // we want, since the nullspace of P (+) -Q are the pairs (x; y) such that
    // Px - Qy = 0 <~~~~> Px = Qy.
    NSMutableArray *nullspace = [sum kernel];
    
    EXTMatrix *leftinclusion = [EXTMatrix matrixWidth:nullspace.count
                                               height:left.width],
              *rightinclusion = [EXTMatrix matrixWidth:nullspace.count
                                                height:right.width];
    
    for (int i = 0; i < nullspace.count; i++) {
        NSArray *col = nullspace[i];
        
        for (int j = 0; j < left.width; j++) {
            NSMutableArray *leftcol = leftinclusion.presentation[i];
            leftcol[j] = col[j];
        }
        
        for (int j = 0; j < right.width; j++) {
            NSMutableArray *rightcol = rightinclusion.presentation[i];
            rightcol[j] = col[j + left.width];
        }
    }
    
    return @[leftinclusion, rightinclusion];
}

+(EXTMatrix*) sum:(EXTMatrix*)a with:(EXTMatrix*)b {
    if ((a.height != b.height) || (a.width != b.width) ||
        (a.characteristic != b.characteristic))
        return nil;
    
    EXTMatrix *ret = [EXTMatrix matrixWidth:a.width height:a.height];
    ret.characteristic = a.characteristic;
    
    for (int i = 0; i < a.width; i++) {
        NSMutableArray *acol = a.presentation[i],
                       *bcol = b.presentation[i],
                     *retcol = ret.presentation[i];
        
        for (int j = 0; j < a.height; j++)
            retcol[j] = @([acol[j] intValue] + [bcol[j] intValue]);
    }
    
    return ret;
}

// debug routine to dump the matrix to the console.
-(void) log {
    for (int i = 0; i < width; i++) {
        NSString *output = @"";
        
        for (int j = 0; j < height; j++) {
            output = [output stringByAppendingFormat:@"%@, ",
                      [[presentation objectAtIndex:i] objectAtIndex:j]];
        }
        
        NSLog(@"%@", output);
    }
}

// here we have a pair of inclusions B --> C <-- Z, with the implicit assumption
// that B --> C factors through B --> Z --> C.  we find a presentation of the
// quotient Z/B in the sequence B --> Z --> Z/B.
+(NSDictionary*) findOrdersOf:(EXTMatrix*)B in:(EXTMatrix*)Z {
    // start by forming the pullback square.
    NSArray *pair = [EXTMatrix formIntersection:Z with:B];
    EXTMatrix *left = pair[0], *right = pair[1];
    EXTMatrix *invertedRight = [right invert];
    
    // since im Z >= im B and both are full rank, the map P --> B is invertible
    // and B --> P --> Z expresses B as a subspace of Z.
    EXTMatrix *inclusion = [EXTMatrix newMultiply:left by:invertedRight];
    
    // pad this out to a map B (+) R --(old map (+) 0)-> Z so that the
    // dimensions line up.
    for (int i = inclusion.width; i < inclusion.height; i++) {
        NSMutableArray *column =
                            [NSMutableArray arrayWithCapacity:inclusion.height];
        for (int j = 0; j < inclusion.height; j++)
            column[j] = @0;
        inclusion.presentation[i] = column;
    }
    inclusion.width = inclusion.height;
    
    // write this new map as (invertible1 . diagonal . invertible2) with the
    // outer matrices of determinant 1.  this can be done by column and row
    // reduction.
    NSArray *columnReduction = [inclusion columnReduceWithRightFactor],
            *rowReduction = [[EXTMatrix copyTranspose:columnReduction[0]]
                                                columnReduceWithRightFactor],
            *factorization = @[[[EXTMatrix copyTranspose:rowReduction[1]] invert],
                               [EXTMatrix copyTranspose:rowReduction[0]],
                               [(EXTMatrix*)columnReduction[1] invert]];
    
    // the diagonal entries give the orders of the abelian group decomposition.
    // (the order '0' means that this factor is torsionfree.) the matrix
    // invertible1^-1 . invertible2^-1 gives a column-matrix of vectors
    // generating these factors.
    //
    // store these in a dictionary.
    EXTMatrix *columns =
            [EXTMatrix newMultiply:Z
                                by:[EXTMatrix newMultiply:factorization[0]
                                                       by:factorization[2]]];
    NSMutableDictionary *ret = [NSMutableDictionary new];
    
    for (int i = 0; i < columns.width; i++) {
        NSArray *column = ((EXTMatrix*)factorization[1]).presentation[i];
        int order = 0;
        for (int j = 0; j < column.count; j++)
            if ([column[j] intValue] != 0) {
                if (order != 0)
                    DLog(@"I got triggered twice...");
                order = [column[j] intValue];
            }
        
        // skip this vector if it is perfectly quotiented out.
        if (order == 1 || order == -1)
            continue;
        
        [ret setObject:@(order) forKey:columns.presentation[i]];
    }
    
    return ret;
}

@end
