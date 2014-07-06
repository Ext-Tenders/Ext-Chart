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
    
    int *selfPresentation = self.presentation.mutableBytes,
        *matPresentation = mat.presentation.mutableBytes;
    
    for (int i = 0; i < self.width; i++)
        for (int j = 0; j < self.height; j++) {
            int s = selfPresentation[i*self.height+j],
                m = matPresentation[i*mat.height+j];
            
            if (s >= self.characteristic && self.characteristic != 0) {
                s %= self.characteristic;
                selfPresentation[i*self.height+j] = s;
            }
            
            if (m >= self.characteristic && self.characteristic != 0) {
                m %= self.characteristic;
                matPresentation[i*mat.height+j] = m;
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
    
    obj.presentation = [NSMutableData dataWithLength:(sizeof(int)*newHeight*newWidth)];
    
    return obj;
}

+(NSArray*) hadamardVectors:(NSArray*)left with:(NSArray*)right {
    EXTMatrix *leftMat = [EXTMatrix matrixWidth:1 height:left.count],
              *rightMat = [EXTMatrix matrixWidth:1 height:right.count];
    
    int *leftMatData = leftMat.presentation.mutableBytes,
        *rightMatData = rightMat.presentation.mutableBytes;
    
    for (int i = 0; i < left.count; i++)
        leftMatData[i] = [left[i] intValue];
    
    for (int i = 0; i < right.count; i++)
        rightMatData[i] = [right[i] intValue];
    
    EXTMatrix *hadamardMat = [EXTMatrix hadamardProduct:leftMat with:rightMat];
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:hadamardMat.height];
    
    int *hadamardData = hadamardMat.presentation.mutableBytes;
    
    for (int i = 0; i < hadamardMat.height; i++)
        ret[i] = @(hadamardData[i]);
    
    return ret;
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
    
    int *retData = ret.presentation.mutableBytes,
        *leftData = left.presentation.mutableBytes,
        *rightData = right.presentation.mutableBytes;
    
    for (int i = 0; i < left.width; i++) {
        for (int j = 0; j < right.width; j++) {
            for (int k = 0; k < left.height; k++) {
                for (int l = 0; l < right.height; l++) {
                    int val = leftData[i*left.height+k] * rightData[j*right.height+l];
                    if (ret.characteristic != 0)
                        val %= ret.characteristic;
                    retData[(i*right.width+j)*ret.height+k*right.height+l] = val;
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
    
    int *data = ret.presentation.mutableBytes;
    
    // poke some 1s into the right places :)
    for (int i = 0; i < startDim; i++)
        data[(offset+spacing*i)*ret.height+i] = 1;
    
    return ret;
}

// allocates and initializes a new matrix 
+(EXTMatrix*) copyTranspose:(EXTMatrix *)input {
    EXTMatrix *ret = [EXTMatrix new];
    ret.width = input.height; ret.height = input.width;
    ret.characteristic = input.characteristic;
    ret.presentation = [NSMutableData dataWithLength:input.presentation.length];
    
    int *inputBytes = input.presentation.mutableBytes,
        *retBytes = ret.presentation.mutableBytes;
    
    for (int i = 0; i < input.width; i++)
        for (int j = 0; j < input.height; j++)
            retBytes[j*ret.height+i] = inputBytes[i*input.height+j];
    
    return ret;
}

// replaces all the elements of a matrix with their reductions mod char
-(EXTMatrix*) modularReduction {
    if (self.characteristic == 0)
        return self;
    
    int *data = self.presentation.mutableBytes;
    
    for (int i = 0; i < width; i++)
        for (int j = 0; j < height; j++)
            data[i*self.height+j] %= self.characteristic;
    
    return self;
}

// performs a deep copy of the matrix
-(EXTMatrix*) copy {
    EXTMatrix *copy = [EXTMatrix new];
    copy.width = width; copy.height = height;
    copy.presentation = [NSMutableData dataWithData:self.presentation];
    copy.characteristic = self.characteristic;
    
    return copy;
}

-(NSArray*) columnReduceWithRightFactor:(bool)dealWithFactor
                               andLimit:(int)limit {
    EXTMatrix *ret = [self copy],
              *rightFactor = [EXTMatrix identity:self.width];
    
    int *retData = ret.presentation.mutableBytes;
    
    // manually allocated data
    bool *usedColumns = calloc(sizeof(bool), width);
    int *row = calloc(sizeof(int), width),
        *rowToBezout = calloc(sizeof(int), width),
        *bezout = calloc(sizeof(int), width);
    
    for (int pivotRow = 0, pivotColumn = 0;
         pivotRow < limit;
         pivotRow++) {
        
        int j, firstNonzeroEntry = -1;
        memset(row, 0, width*sizeof(int));
        memset(rowToBezout, 0, width*sizeof(int));
        
        // save this row for analysis.
        for (int k = 0; k < width; k++) {
            row[k] = retData[k*ret.height + pivotRow];
            
            if (usedColumns[k])
                rowToBezout[k] = 0;
            else
                rowToBezout[k] = retData[k*ret.height+pivotRow];
            
            if (firstNonzeroEntry == -1 && row[k] != 0)
                firstNonzeroEntry = k;
        }
        
        if (firstNonzeroEntry == -1)
            continue;
        
        // compute the bezout vector for this row.
        memset(bezout, 0, width*sizeof(int));
        int gcd = rowToBezout[firstNonzeroEntry];
        for (int k = 0; k < firstNonzeroEntry; k++)
            bezout[k] = 0;
        bezout[firstNonzeroEntry] = 1;
        
        for (NSInteger index = firstNonzeroEntry + 1;
             index < width;
             index++) {
            
            // don't look at this column if it's already been used.
            if (usedColumns[index]) {
                bezout[index] = 0;
                continue;
            }
            
            // if this can't contribute anything, don't even bother with it.
            if (row[index] == 0) {
                bezout[index] = 0;
                continue;
            }
            
            int a = gcd,
                b = row[index],
                newGcd = 0,
                r = 0,
                s = 0;
            
            EXTComputeGCD(&a, &b, &newGcd, &r, &s);
            
            if (abs(gcd) == abs(newGcd)) {
                bezout[index] = 0;
                continue;
            }
            
            gcd = newGcd;
            bezout[index] = s;
            for (NSInteger j = 0; j < index; j++)
                bezout[j] = bezout[j] * r;
        }
        
        // find the first nonzero entry in this row, right of where we're at
        int highStrikerValue = 0, highStrikerKey = width;
        for (j = 0; j < width; j++) {
            if (usedColumns[j])
                continue;
            if (0 != bezout[j]) {
                if (abs(row[j]) > highStrikerValue) {
                    highStrikerKey = j;
                    highStrikerValue = abs(row[j]);
                }
            }
        }
        
        // if we found a nonzero entry, then this is the new pivot column.
        // if we didn't, then we should skip this row entirely.
        if (highStrikerKey == width)
            continue;
        else {
            pivotColumn = highStrikerKey;
            usedColumns[highStrikerKey] = true;
        }
        
        // if we've made it here, then we have a new pivot location, and we're
        // tasked with clearing the rest of the row of nonzero entries.
        //
        // start by replacing this column with the Bezout-weighted sum of the
        // old columns.
        NSMutableArray *bezoutArray = [NSMutableArray arrayWithCapacity:width];
        for (int j = 0; j < width; j++)
            bezoutArray[j] = @(bezout[j]);
        NSArray *newColumn = [ret actOn:bezoutArray];
        for (int j = 0; j < height; j++)
            retData[pivotColumn*ret.height+j] = [newColumn[j] intValue];
        
        EXTMatrix *rightmostFactor = [EXTMatrix identity:self.width];
        int *rightmostData = rightmostFactor.presentation.mutableBytes;
        for (int j = 0; j < width; j++)
            rightmostData[pivotColumn*rightmostFactor.height+j] = bezout[j];
        
        // then iterate through the other columns...
        for (j = 0; j < width; j++) {
            //NSMutableArray *workingColumn = ret.presentation[j],
            //               *factorColumn = rightmostFactor.presentation[j];
            
            // skip the column if this row is already zeroed out.
            if (retData[j*ret.height+pivotRow] == 0)
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
            int factor = 0;
            if (retData[pivotColumn*ret.height+pivotRow] != 0)
                factor = retData[j*ret.height+pivotRow] /
                                    retData[pivotColumn*ret.height+pivotRow];
            
            // ... and for each entry in this column, subtract.
            for (int i = 0; i < height; i++) {
                retData[j*ret.height+i] -= factor * retData[pivotColumn*ret.height+i];
            }
            
            for (int i = 0; i < width; i++) {
                rightmostData[j*rightmostFactor.height+i] -= factor * bezout[i];
            }
        }
        
        // if necessary, put the matrix back in its modular equivalence class.
        [ret modularReduction];
        
        rightFactor = [EXTMatrix newMultiply:rightFactor by:rightmostFactor];
    }
    
    // manually deallocate data
    free(usedColumns);
    free(rowToBezout);
    free(row);
    free(bezout);
    usedColumns = NULL;
    rowToBezout = row = bezout = NULL;
    
    return @[ret, rightFactor];
}

// runs gaussian column reduction on a matrix over Z.  useful for finding a
// presentation of the image of the matrix.
-(EXTMatrix*) columnReduce {
    return (EXTMatrix*)([self columnReduceWithRightFactor:true andLimit:self.height][0]);
}

// returns a basis for the kernel of a matrix
-(EXTMatrix*) kernel {
    // vertically augment the matrix by an identity matrix
    EXTMatrix *augmentedMatrix = [EXTMatrix matrixWidth:self.width height:(self.height + self.width)];
    augmentedMatrix.characteristic = self.characteristic;
    
    int *data = self.presentation.mutableBytes,
        *augmentedData = augmentedMatrix.presentation.mutableBytes;
    
    for (int i = 0; i < self.width; i++) {
        // copy over the top of the matrix
        for (int j = 0; j < self.height; j++)
            augmentedData[i*augmentedMatrix.height + j] = data[i*self.height + j];
    }
    for (int i = 0; i < self.width; i++)
        augmentedData[i*augmentedMatrix.height + i + self.height] = 1;
    
    // column-reduce the augmented matrix
    EXTMatrix *reducedMatrix = [augmentedMatrix columnReduce];
    
    // read off the augmented columns corresponding to zero columns in the orig
    EXTMatrix *ret = [EXTMatrix matrixWidth:0 height:self.width];
    
    int *reducedData = reducedMatrix.presentation.mutableBytes;
    
    for (int i = 0; i < reducedMatrix.width; i++) {
        // test to see if the original column is full of zeroes
        bool skipme = false;
        for (int j = 0; j < self.height; j++)
            if (reducedData[i*reducedMatrix.height+j] != 0)
                skipme = true;
        if (skipme)   // if we found nonzero entries...
            continue; // ... skip this column.
        
        // otherwise, there's something here to copy.
        // 1) stretch the return matrix
        ret.width += 1;
        [ret.presentation increaseLengthBy:(sizeof(int)*self.width)];
        
        int *retData = ret.presentation.mutableBytes;
        
        // 2) copy the new column vector
        for (int j = self.height; j < reducedMatrix.height; j++)
            retData[(ret.width-1)*ret.height+(j-self.height)] = reducedData[i*reducedMatrix.height+j];
    }
    
    // that's a basis for the kernel!
    return ret;
}

// returns a basis for the image of a matrix
-(EXTMatrix*) image {
    EXTMatrix *reduced = [self columnReduce];
    EXTMatrix *ret = [EXTMatrix matrixWidth:0 height:self.height];
    
    int *reducedData = reduced.presentation.mutableBytes;
    
    // iterate through the columns
    for (int i = 0; i < reduced.width; i++) {
        // test to see if the column is not all zeroes
        bool skipit = true;
        for (int j = 0; j < reduced.height; j++)
            if (reducedData[i*reduced.height+j] != 0)
                skipit = false;
        
        if (skipit)   // it's all zeroes...
            continue; // so skip it.
        
        // and, if it's not all zeroes, we should add it to the collection.
        // 1) expand the array
        ret.width += 1;
        [ret.presentation increaseLengthBy:(sizeof(int)*reduced.height)];
        int *retData = ret.presentation.mutableBytes;
        // 2) copy the image vector over
        for (int j = 0; j < reduced.height; j++)
            retData[(ret.width-1)*ret.height+j] = reducedData[i*reduced.height+j];
    }
    
    return ret;
}

// returns the product of two matrices.
+(EXTMatrix*) newMultiply:(EXTMatrix*)left by:(EXTMatrix*)right {
    if (left.width != right.height)
        NSLog(@"Mismatched multiplication.");
    
    EXTMatrix *product = [EXTMatrix matrixWidth:right.width height:left.height];
    {
        int a = left.characteristic,
            b = right.characteristic,
            gcd = 0;
        
        EXTComputeGCD(&a, &b, &gcd, NULL, NULL);
        
        product.characteristic = gcd;
    }
    
    int *leftData = left.presentation.mutableBytes,
        *rightData = right.presentation.mutableBytes,
        *productData = product.presentation.mutableBytes;
    
    for (int k = 0; k < [right width]; k++)
        for (int i = 0; i < [left height]; i++)
            for (int j = 0; j < [left width]; j++)
                productData[product.height*k+i] += rightData[k*right.height+j] * leftData[j*left.height+i];
    
    [product modularReduction];
    
    return product;
}

// matrix acts on a vector from the left.
-(NSMutableArray*) actOn:(NSArray *)vector {
    EXTMatrix *tempMatrix = [EXTMatrix matrixWidth:1 height:vector.count];
    tempMatrix.characteristic = self.characteristic;
    
    for (int i = 0; i < vector.count; i++)
        ((int*)tempMatrix.presentation.mutableBytes)[i] = [vector[i] intValue];
    
    EXTMatrix *product = [EXTMatrix newMultiply:self by:tempMatrix];
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:product.height];
    
    for (int i = 0; i < product.height; i++)
        result[i] = @(((int*)product.presentation.mutableBytes)[i]);
    
    return result;
}

+(EXTMatrix*) identity:(int)width {
    EXTMatrix *ret = [EXTMatrix matrixWidth:width height:width];
    
    int *retData = ret.presentation.mutableBytes;
    
    for (int i = 0; i < width; i++)
        retData[i*ret.height+i] = 1;
    
    return ret;
}

-(EXTMatrix*) invert {
    if (height != width)
        return nil;
    
    // augment the matrix by the identity
    EXTMatrix *temp = [self copy];
    [temp.presentation increaseLengthBy:(sizeof(int)*sizeof(height)*sizeof(width))];
    
    int *tempData = temp.presentation.mutableBytes;
    for (int i = 0; i < temp.height; i++)
        tempData[(temp.width + i)*(temp.height) + i] = 1;
    temp.width *= 2;
    
    // TODO: are these two calls to copyTranspose wasteful?
    // perform column reduction
    EXTMatrix *flip = [EXTMatrix copyTranspose:temp];
    [flip columnReduce];
    EXTMatrix *unflip = [EXTMatrix copyTranspose:flip];
    
    // peel off the inverse from the augmented portion
    // XXX: some kind of error checking would be nice
    EXTMatrix *ret = [EXTMatrix matrixWidth:self.width height:self.width];
    ret.characteristic = self.characteristic;
    
    int *retData = ret.presentation.mutableBytes,
        *unflipData = unflip.presentation.mutableBytes;
    for (int i = 0; i < self.width; i++) {
        for (int j = 0; j < self.height; j++)
            retData[i*self.height + j] = unflipData[(i+self.width)*(self.height)+j];
    }
    
    return ret;
}

-(int) rank {
    EXTMatrix *image = [self image];
    
    return image.width;
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
    
    // then, get a characteristic and a total dimension.
    int characteristic =
        ((EXTPartialDefinition*)partialDefinitions[0]).action.characteristic;
    for (EXTPartialDefinition *partial in partialDefinitions)
        if (characteristic != partial.action.characteristic ||
            characteristic != partial.inclusion.characteristic) {
            EXTLog(@"Unequal characteristics in presentation assembly.");
        }
    
    int totalWidth = 0;
    for (EXTPartialDefinition *partial in partialDefinitions)
        totalWidth += partial.inclusion.width;
    
    // form the block matrix:
    // I1 | I2 | ... | In | Iheight
    // ----------------------------
    // P1 | P2 | ... | Pn |  zero
    EXTMatrix *bigMatrix =
            [EXTMatrix matrixWidth:(totalWidth + sourceDimension)
                            height:(sourceDimension + targetDimension)];
    bigMatrix.characteristic = characteristic;
    bigMatrix.width = 0; // we'll push this back out as we go
    
    int *bigData = bigMatrix.presentation.mutableBytes;
    for (EXTPartialDefinition *partial in partialDefinitions) {
        int *inclusionData = partial.inclusion.presentation.mutableBytes,
            *actionData = partial.action.presentation.mutableBytes;
        for (int i = 0; i < partial.inclusion.width; i++) {
            for (int j = 0; j < partial.inclusion.height; j++)
                bigData[bigMatrix.height*(i+bigMatrix.width) + j] = inclusionData[partial.inclusion.height*i + j];
            for (int j = 0; j < partial.action.height; j++)
                bigData[bigMatrix.height*(i+bigMatrix.width) + partial.inclusion.height + j] = actionData[partial.action.height*i + j];
        }
        bigMatrix.width += partial.inclusion.width;
    }
    for (int i = totalWidth; i < totalWidth + sourceDimension; i++)
        bigData[i*bigMatrix.height + i] = 1;
    
    // now, perform our usual left-to-right column reduction to it.
    // TODO: implement a version of cRWRFAL that doesn't compute the right factor
    EXTMatrix *reducedMatrix = [bigMatrix columnReduceWithRightFactor:true andLimit:sourceDimension][0];
    
    // we find those columns of the form [ej; stuff], and extract the 'stuff'
    // from this column. this is our differential.
    EXTMatrix *difflInCoordinates = [EXTMatrix matrixWidth:sourceDimension height:targetDimension];
    difflInCoordinates.characteristic = characteristic;
    
    int *difflInCoordData = difflInCoordinates.presentation.mutableBytes,
        *reducedData = reducedMatrix.presentation.mutableBytes;
    for (int i = 0; i < reducedMatrix.width; i++) {
        int pivotRow = -1;
        
        for (int j = 0; j < sourceDimension; j++)
            if (abs(reducedData[i*reducedMatrix.height+j]) == 1)
                pivotRow = j;
        if (pivotRow == -1)
            continue;
        
        // extracts the stuff.
        for (int j = 0; j < targetDimension; j++)
            difflInCoordData[pivotRow*difflInCoordinates.height+j] = reducedData[reducedMatrix.height*i+sourceDimension+j];
    }
    
    return difflInCoordinates;
}

// returns a scaled matrix
-(EXTMatrix*) scale:(int)scalar {
    EXTMatrix *ret = [self copy];
    
    int *retData = ret.presentation.mutableBytes;
    for (int i = 0; i < ret.width; i++)
        for (int j = 0; j < ret.height; j++)
            retData[i*ret.height+j] *= scalar;
    
    [ret modularReduction];
    
    return ret;
}

// given a cospan A --> C <-- B, this routine forms the pullback span.
+(NSArray*) formIntersection:(EXTMatrix*)left with:(EXTMatrix*)right {
    // perform cleanup to put us in a good state.
    [left modularReduction];
    [right modularReduction];
    
    // form the matrix [P, -Q]
    EXTMatrix *negRight = [right scale:-1];
    EXTMatrix *sum = [left copy];
    [sum.presentation appendData:negRight.presentation];
    sum.width += right.width;
    
    // the nullspace of [P, -Q] is a vertical sum [I; J] of the two inclusions
    // we want, since the nullspace of P (+) -Q are the pairs (x; y) such that
    // Px - Qy = 0 <~~~~> Px = Qy.
    EXTMatrix *nullspace = [sum kernel];
    
    EXTMatrix *leftinclusion = [EXTMatrix matrixWidth:nullspace.width
                                               height:left.width],
              *rightinclusion = [EXTMatrix matrixWidth:nullspace.width
                                                height:right.width];
    leftinclusion.characteristic = left.characteristic;
    rightinclusion.characteristic = right.characteristic;
    
    int *nullData = nullspace.presentation.mutableBytes,
        *leftInclData = leftinclusion.presentation.mutableBytes,
        *rightInclData = rightinclusion.presentation.mutableBytes;
    for (int i = 0; i < nullspace.width; i++) {
        for (int j = 0; j < left.width; j++)
            leftInclData[i*leftinclusion.height+j] = nullData[i*nullspace.height+j];
        
        for (int j = 0; j < right.width; j++)
            rightInclData[i*rightinclusion.height+j] = nullData[i*nullspace.height+left.width+j];
    }
    
    return @[leftinclusion, rightinclusion];
}

+(EXTMatrix*) sum:(EXTMatrix*)a with:(EXTMatrix*)b {
    if ((a.height != b.height) || (a.width != b.width) ||
        (a.characteristic != b.characteristic))
        return nil;
    
    EXTMatrix *ret = [EXTMatrix matrixWidth:a.width height:a.height];
    ret.characteristic = a.characteristic;
    
    int *retData = ret.presentation.mutableBytes,
        *aData = a.presentation.mutableBytes,
        *bData = b.presentation.mutableBytes;
    for (int i = 0; i < ret.width; i++)
        for (int j = 0; j < ret.height; j++)
            retData[i*ret.height+j] = aData[i*ret.height+j] + bData[i*ret.height+j];
    
    return ret;
}

// debug routine to dump the matrix to the console.
-(NSString*) description {
    NSString *ret = [NSString stringWithFormat:@"%lu x %lu: (", height, width];
    for (int i = 0; i < width; i++) {
        NSString *output = @"";
        
        for (int j = 0; j < height; j++) {
            output = [output stringByAppendingFormat:@"%d, ",
                      ((int*)presentation.mutableBytes)[i*height+j]];
        }
        
        ret = [NSString stringWithFormat:@"%@| %@|",ret, output];
    }
    
    return [NSString stringWithFormat:@"%@)",ret];
}

// here we have a pair of inclusions B --> C <-- Z, with the implicit assumption
// that B --> C factors through B --> Z --> C.  we find a presentation of the
// quotient Z/B in the sequence B --> Z --> Z/B in terms of the classification
// theorem for finitely generated modules over a Euclidean domain.
+(NSDictionary*) findOrdersOf:(EXTMatrix*)B in:(EXTMatrix*)Z {
    // start by forming the pullback square.
    NSArray *pair = [EXTMatrix formIntersection:Z with:B];
    EXTMatrix *left = pair[0], *right = pair[1];
    EXTMatrix *invertedRight = [right invert];
    
    if (!invertedRight)
        NSLog(@"B does not live in Z.");
    
    // since im Z >= im B and both are full rank, the map P --> B is invertible
    // and B --> P --> Z expresses B as a subspace of Z.
    EXTMatrix *inclusion = [EXTMatrix newMultiply:left by:invertedRight];
    
    // pad this out to a map B (+) R --(old map (+) 0)-> Z so that the
    // dimensions line up.
    [inclusion.presentation increaseLengthBy:((inclusion.height-inclusion.width)*inclusion.height*sizeof(int))];
    inclusion.width = inclusion.height;
    
    // write this new map as (invertible1 . quasidiagonal . invertible2) with
    // the outer matrices of determinant 1.  this can be done by column and row
    // reduction.
    NSArray *columnReduction = [inclusion columnReduceWithRightFactor:true
                                                    andLimit:inclusion.height],
            *rowReduction = [[EXTMatrix copyTranspose:columnReduction[0]]
                             columnReduceWithRightFactor:true
                             andLimit:((EXTMatrix*)columnReduction[0]).width],
            *factorization = @[[[EXTMatrix copyTranspose:rowReduction[1]] invert],
                               [EXTMatrix copyTranspose:rowReduction[0]],
                               [(EXTMatrix*)columnReduction[1] invert]];
    
    EXTMatrix *middleMatrix = factorization[1];
    
    // the diagonal entries give the orders of the abelian group decomposition.
    // (the order '0' means that this factor is torsionfree.) this is
    // complicated slightly by the middle matrix being only quasidiagonal.  so,
    // we take the old middle matrix, replace all its nonzero entries by 1s, and
    // then poke in extra 1s so that every row and every column has precisely one
    // 1 in it. the resulting matrix
    //            invertible1^-1 . divisibleSubspace . invertible2^-1
    // gives a column-matrix of vectors generating these factors.
    EXTMatrix *divisibleSubspace = [middleMatrix copy];
    int *divisibleData = divisibleSubspace.presentation.mutableBytes;
    for (int i = 0; i < divisibleSubspace.width; i++) {
        // either this column has a nonzero element in it or it doesn't.
        bool isAllZeroes = true;
        
        for (int j = 0; j < divisibleSubspace.height; j++) {
            if (divisibleData[divisibleSubspace.height*i + j] == 0)
                continue;
            
            divisibleData[divisibleSubspace.height*i + j] = 1;
            isAllZeroes = false;
        }
        
        if (!isAllZeroes)
            continue;
        
        for (int j = 0; j < divisibleSubspace.height; j++) {
            bool rowIsAllZeroes = true;
            
            for (int iprime = 0; iprime < divisibleSubspace.width; iprime++)
                if (divisibleData[iprime*divisibleSubspace.height+j] != 0)
                    rowIsAllZeroes = false;
            
            if (!rowIsAllZeroes)
                continue;
            
            divisibleData[i*divisibleSubspace.height+j] = 1;
            break;
        }
    }
    
    EXTMatrix *columns =
            [EXTMatrix newMultiply:Z
                by:[EXTMatrix newMultiply:factorization[0]
                    by:[EXTMatrix newMultiply:divisibleSubspace
                                           by:factorization[2]]]];
    NSMutableDictionary *ret = [NSMutableDictionary new];
    
    int *orderData = middleMatrix.presentation.mutableBytes,
        *columnsData = columns.presentation.mutableBytes;
    for (int i = 0; i < columns.width; i++) {
        int order = 0;
        for (int j = 0; j < middleMatrix.height; j++)
            if (orderData[i*middleMatrix.height+j] != 0) {
                if (order != 0)
                    DLog(@"I got triggered twice...");
                order = orderData[i*middleMatrix.height+j];
            }
        
        // skip this vector if it is perfectly quotiented out.
        if (order == 1 || order == -1)
            continue;
        
        NSMutableArray *column = [NSMutableArray arrayWithCapacity:middleMatrix.height];
        for (int j = 0; j < middleMatrix.height; j++)
            column[j] = @(columnsData[i*columns.height+j]);
        
        [ret setObject:@(order) forKey:column];
    }
    
    return ret;
}

+(int) rankOfMap:(EXTMatrix*)map intoQuotientByTheInclusion:(EXTMatrix*)incl {
    NSArray *span = [EXTMatrix formIntersection:map with:incl];
    EXTMatrix *reducedMatrix = [(EXTMatrix*)span[0] columnReduce];
    int imageSize = map.width;
    int *reducedData = reducedMatrix.presentation.mutableBytes;
    for (int i = 0; i < reducedMatrix.width; i++) {
        bool decrement = false;
        
        for (int j = 0; j < reducedMatrix.height; j++)
            if (abs(reducedData[i*reducedMatrix.height+j]) == 1)
                decrement = true;
        
        if (decrement)
            imageSize--;
    }
    
    return imageSize;
}

@end
