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

+(NSArray*) hadamardVectors:(NSArray*)left with:(NSArray*)right {
    EXTMatrix *leftMat = [EXTMatrix matrixWidth:1 height:left.count],
              *rightMat = [EXTMatrix matrixWidth:1 height:right.count];
    leftMat.presentation[0] = [NSMutableArray arrayWithArray:left];
    rightMat.presentation[0] = [NSMutableArray arrayWithArray:right];
    return [EXTMatrix hadamardProduct:leftMat with:rightMat].presentation[0];
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
    EXTMatrix *ret = [EXTMatrix new];
    ret.width = input.height; ret.height = input.width;
    ret.presentation = [NSMutableArray arrayWithCapacity:ret.width];
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
    EXTMatrix *copy = [EXTMatrix new];
    copy.width = width; copy.height = height;
    copy.presentation = [NSMutableArray arrayWithCapacity:width];
    copy.characteristic = self.characteristic;
    
    for (int i = 0; i < width; i++) {
        NSMutableArray *column = (copy.presentation[i] = [NSMutableArray arrayWithCapacity:height]);
    
        for (int j = 0; j < height; j++) {
            NSNumber *num = ((NSArray*)presentation[i])[j];
            column[j] = num;
        }
    }
    
    return copy;
}

-(NSArray*) columnReduceWithRightFactorAndLimit:(int)limit {
    EXTMatrix *ret = [self copy],
              *rightFactor = [EXTMatrix identity:self.width];
    NSMutableArray *usedColumns = [NSMutableArray array];
    for (int i = 0; i < width; i++)
        usedColumns[i] = @(false);
    
    for (int pivotRow = 0, pivotColumn = 0;
         pivotRow < limit;
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
        int highStrikerValue = 0, highStrikerKey = width;
        for (j = 0; j < width; j++) {
            if ([usedColumns[j] intValue])
                continue;
            if (0 != [bezout[j] intValue]) {
                if (abs([row[j] intValue]) > highStrikerValue) {
                    highStrikerKey = j;
                    highStrikerValue = abs([row[j] intValue]);
                }
            }
        }
        
        // if we found a nonzero entry, then this is the new pivot column.
        // if we didn't, then we should skip this row entirely.
        if (highStrikerKey == width)
            continue;
        else {
            pivotColumn = highStrikerKey;
            usedColumns[highStrikerKey] = @(true);
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
    return (EXTMatrix*)([self columnReduceWithRightFactorAndLimit:self.height][0]);
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
        [ret addObject:reduced.presentation[i]];
    }
    
    return ret;
}

// returns the product of two matrices.
+(EXTMatrix*) newMultiply:(EXTMatrix*)left by:(EXTMatrix*)right {
    if (left.width != right.height)
        NSLog(@"Mismatched multiplication.");
    
    EXTMatrix *product = [EXTMatrix new];
    product.width = right.width;
    product.height = left.height;
    product.presentation = [NSMutableArray arrayWithCapacity:product.width];
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
    EXTMatrix *ret = [EXTMatrix new];
    ret.width = self.width; ret.height = self.width;
    ret.presentation = [NSMutableArray arrayWithCapacity:self.width];
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
            [EXTMatrix matrixWidth:0
                            height:(sourceDimension + targetDimension)];
    for (EXTPartialDefinition *partial in partialDefinitions) {
        for (int i = 0; i < partial.inclusion.width; i++) {
            NSMutableArray *bigColumn = [NSMutableArray array];
            [bigColumn addObjectsFromArray:partial.inclusion.presentation[i]];
            [bigColumn addObjectsFromArray:partial.action.presentation[i]];
            [bigMatrix.presentation addObject:bigColumn];
        }
    }
    for (int i = totalWidth; i < totalWidth + sourceDimension; i++) {
        NSMutableArray *column = [NSMutableArray array];
        for (int j = 0; j < targetDimension + sourceDimension; j++) {
            if (j == i - totalWidth)
                column[j] = @1;
            else
                column[j] = @0;
        }
        [bigMatrix.presentation addObject:column];
    }
    bigMatrix.width = totalWidth + sourceDimension;
    bigMatrix.characteristic = characteristic;
    
    // now, perform our usual left-to-right column reduction to it.
    EXTMatrix *reducedMatrix = [bigMatrix columnReduceWithRightFactorAndLimit:sourceDimension][0];
    
    // we find those columns of the form [ej; stuff], and extract the 'stuff'
    // from this column. this is our differential.
    EXTMatrix *difflInCoordinates = [EXTMatrix matrixWidth:sourceDimension height:targetDimension];
    for (int i = 0; i < reducedMatrix.width; i++) {
        int pivotRow = -1;
        NSArray *column = reducedMatrix.presentation[i];
        
        for (int j = 0; j < sourceDimension; j++)
            if (abs([column[j] intValue]) == 1)
                pivotRow = j;
        if (pivotRow == -1)
            continue;
        
        // extracts the stuff.
        difflInCoordinates.presentation[pivotRow] = [NSMutableArray arrayWithArray:[column subarrayWithRange:NSMakeRange(sourceDimension, targetDimension)]];
    }
    difflInCoordinates.characteristic = characteristic;
    
    return difflInCoordinates;
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
    EXTMatrix *sum = [EXTMatrix new];
    sum.width = left.width + right.width; sum.height = left.height;
    sum.presentation = [NSMutableArray arrayWithArray:left.presentation];
    [sum.presentation addObjectsFromArray:[right scale:(-1)].presentation];
    sum.characteristic = left.characteristic;
    
    // the nullspace of [P, -Q] is a vertical sum [I; J] of the two inclusions
    // we want, since the nullspace of P (+) -Q are the pairs (x; y) such that
    // Px - Qy = 0 <~~~~> Px = Qy.
    NSMutableArray *nullspace = [sum kernel];
    
    EXTMatrix *leftinclusion = [EXTMatrix matrixWidth:nullspace.count
                                               height:left.width],
              *rightinclusion = [EXTMatrix matrixWidth:nullspace.count
                                                height:right.width];
    leftinclusion.width = nullspace.count; leftinclusion.height = left.width;
    rightinclusion.width = nullspace.count; rightinclusion.height = right.width;
    leftinclusion.presentation = [NSMutableArray arrayWithCapacity:nullspace.count];
    rightinclusion.presentation = [NSMutableArray arrayWithCapacity:nullspace.count];
    
    for (int i = 0; i < nullspace.count; i++) {
        NSArray *col = nullspace[i];
        NSMutableArray *leftcol = (leftinclusion.presentation[i] = [NSMutableArray arrayWithCapacity:left.width]),
                       *rightcol = (rightinclusion.presentation[i] = [NSMutableArray arrayWithCapacity:right.width]);
        
        for (int j = 0; j < left.width; j++) {
            leftcol[j] = col[j];
        }
        
        for (int j = 0; j < right.width; j++) {
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
-(NSString*) description {
    NSString *ret = @"(";
    for (int i = 0; i < width; i++) {
        NSString *output = @"";
        
        for (int j = 0; j < height; j++) {
            output = [output stringByAppendingFormat:@"%@, ",
                      [[presentation objectAtIndex:i] objectAtIndex:j]];
        }
        
        ret = [NSString stringWithFormat:@"%@| %@|",ret, output];
    }
    
    return [NSString stringWithFormat:@"%@]",ret];
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
    for (int i = inclusion.width; i < inclusion.height; i++) {
        NSMutableArray *column =
                            [NSMutableArray arrayWithCapacity:inclusion.height];
        for (int j = 0; j < inclusion.height; j++)
            column[j] = @0;
        inclusion.presentation[i] = column;
    }
    inclusion.width = inclusion.height;
    
    // write this new map as (invertible1 . quasidiagonal . invertible2) with
    // the outer matrices of determinant 1.  this can be done by column and row
    // reduction.
    NSArray *columnReduction = [inclusion columnReduceWithRightFactorAndLimit:inclusion.height],
            *rowReduction = [[EXTMatrix copyTranspose:columnReduction[0]]
                                    columnReduceWithRightFactorAndLimit:((EXTMatrix*)columnReduction[0]).width],
            *factorization = @[[[EXTMatrix copyTranspose:rowReduction[1]] invert],
                               [EXTMatrix copyTranspose:rowReduction[0]],
                               [(EXTMatrix*)columnReduction[1] invert]];
    
    // the diagonal entries give the orders of the abelian group decomposition.
    // (the order '0' means that this factor is torsionfree.) this is
    // complicated slightly by the middle matrix being only quasidiagonal.  so,
    // we take the old middle matrix, replace all its nonzero entries by 1s, and
    // then poke in extra 1s so that every row and every column has precisely one
    // 1 in it. the resulting matrix
    //            invertible1^-1 . divisibleSubspace . invertible2^-1
    // gives a column-matrix of vectors generating these factors.
    EXTMatrix *divisibleSubspace = [factorization[1] copy];
    for (int i = 0; i < divisibleSubspace.width; i++) {
        NSMutableArray *column = divisibleSubspace.presentation[i];
        
        // either this column has a nonzero element in it or it doesn't.
        bool isAllZeroes = true;
        
        for (int j = 0; j < divisibleSubspace.height; j++) {
            if ([column[j] intValue] == 0)
                continue;
            
            column[j] = @1;
            isAllZeroes = false;
        }
        
        if (!isAllZeroes)
            continue;
        
        for (int j = 0; j < divisibleSubspace.height; j++) {
            bool rowIsAllZeroes = true;
            
            for (int iprime = 0; iprime < divisibleSubspace.width; iprime++)
                if ([divisibleSubspace.presentation[iprime][j] intValue] != 0)
                    rowIsAllZeroes = false;
            
            if (!rowIsAllZeroes)
                continue;
            
            divisibleSubspace.presentation[i][j] = @1;
            break;
        }
    }
    
    EXTMatrix *columns =
            [EXTMatrix newMultiply:Z
                by:[EXTMatrix newMultiply:factorization[0]
                    by:[EXTMatrix newMultiply:divisibleSubspace
                                           by:factorization[2]]]];
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

+(int) rankOfMap:(EXTMatrix*)map intoQuotientByTheInclusion:(EXTMatrix*)incl {
    NSArray *span = [EXTMatrix formIntersection:map with:incl];
    EXTMatrix *reducedMatrix = [(EXTMatrix*)span[0] columnReduce];
    int imageSize = map.width;
    for (NSArray *column in reducedMatrix.presentation) {
        bool decrement = false;
        
        for (NSNumber *entry in column)
            if (abs([entry intValue]) == 1)
                decrement = true;
        
        if (decrement)
            imageSize--;
    }
    
    return imageSize;
}

@end
