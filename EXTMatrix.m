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
@implementation EXTPartialDefinition

@synthesize inclusion;
@synthesize differential;
@synthesize automaticallyGenerated;

-(EXTPartialDefinition*) init {
    if (!(self = [super init])) return nil;
    
    // we don't keep track of enough information about dimensions to make the
    // appropriate initialization calls to EXTMatrix factories.
    inclusion = nil;
    differential = nil;
    
    return self;
}

-(BOOL) isEqual:(id)object {
    if ([object class] != [EXTPartialDefinition class])
        return false;
    
    EXTPartialDefinition *target = (EXTPartialDefinition*)object;
    
    return ([self.differential isEqual:target.differential] && [self.inclusion isEqual:target.inclusion]);
}

-(void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:inclusion forKey:@"inclusion"];
    [aCoder encodeObject:differential forKey:@"differential"];
}

-(id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        inclusion = [aDecoder decodeObjectForKey:@"inclusion"];
        differential = [aDecoder decodeObjectForKey:@"differential"];
    }
    
    return self;
}

// TODO: make the boolean flag into (change to true)-only, like a dirty flag.
// use this to decide whether to prompt the user when deleting partial
// definitions, or generally when performing any other destructive operation.

@end




@implementation EXTMatrix

// XXX: somehow change the presentation getter to recompute the presentation off
// of the partial definitions --- but ideally not every time we need to access
// the presentation, just when it's somehow "dirty"...
@synthesize height, width;
@synthesize presentation;

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        height = [aDecoder decodeIntForKey:@"height"];
        width = [aDecoder decodeIntForKey:@"width"];
        presentation = [aDecoder decodeObjectForKey:@"presentation"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInt:height forKey:@"height"];
    [aCoder encodeInt:width forKey:@"width"];
    [aCoder encodeObject:presentation forKey:@"presentation"];
}

-(BOOL) isEqual:(id)object {
    if ([object class] != [EXTMatrix class])
        return false;
    
    EXTMatrix *mat = (EXTMatrix*)object;
    
    if ((mat.width != self.width) || (mat.height != self.height))
        return false;
    
    for (int i = 0; i < self.width; i++)
        for (int j = 0; j < self.height; j++)
            if ([((NSMutableArray*)self.presentation[i])[j] intValue] !=
                [((NSMutableArray*)mat.presentation[i])[j] intValue])
                return false;
    
    return true;
}

// initializes an EXTMatrix object and allocates all the NSMutableArrays
// used in the presentation.
+(EXTMatrix*) matrixWidth:(int)newWidth height:(int)newHeight {
    EXTMatrix *obj = [EXTMatrix new];
    
    // set the basic properties
    [obj setHeight:newHeight];
    [obj setWidth:newWidth];
    
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
    
    for (int i = 0; i < left.width; i++) {
        NSMutableArray *leftcol = left.presentation[i];
        for (int j = 0; j < right.width; j++) {
            NSMutableArray *rightcol = right.presentation[j],
                             *retcol = ret.presentation[i*right.width+j];
            for (int k = 0; k < left.height; k++) {
                for (int l = 0; l < right.height; l++) {
                    retcol[k*right.height+l] =
                            @([leftcol[k] intValue] * [rightcol[l] intValue]);
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
    
    for (int i = 0; i < [input height]; i++) {
        NSMutableArray *newColumn =
            [NSMutableArray arrayWithCapacity:input.height];
        
        for (int j = 0; j < [input width]; j++) {
            // read off the subscripts in the inverse order
            [newColumn setObject:[[input.presentation objectAtIndex:j] objectAtIndex:i] atIndexedSubscript:j];
        }
        
        [ret.presentation setObject:newColumn atIndexedSubscript:i];
    }
    
    return ret;
}

// replaces all the elements of a matrix with their reductions mod 2
-(void) modularReduction {
    for (int i = 0; i < width; i++) {
        NSMutableArray *column = [presentation objectAtIndex:i];
        
        for (int j = 0; j < height; j++) {
            [column setObject:@([[column objectAtIndex:j] intValue] % 2)
                    atIndexedSubscript:j];
        }
    }
}

// performs a deep copy of the matrix
-(EXTMatrix*) copy {
    EXTMatrix *copy = [EXTMatrix matrixWidth:width height:height];
    
    for (int i = 0; i < width; i++)
        for (int j = 0; j < height; j++) {
            NSNumber *num = ((NSArray*)presentation[i])[j];
            ((NSMutableArray*)copy.presentation[i])[j] = num;
        }
    
    return copy;
}

// runs gaussian column reduction on a matrix.  useful of course for finding
// a presentation of the image of a matrix.
-(EXTMatrix*) columnReduce {
    int pivotRow = 0, pivotColumn = 0;
    EXTMatrix *ret = [self copy];
    
    for (pivotRow = 0; (pivotRow < height) && (pivotColumn < width); pivotRow++) {
        int j;
        
        // find the first nonzero entry in this row, right of where we're at
        for (j = pivotColumn; j < width; j++) {
            if (0 != [[[ret.presentation objectAtIndex:j]
                       objectAtIndex:pivotRow] intValue])
                break;
        }
        
        // if we found a nonzero entry, then this is the new pivot column.
        // if we didn't, then we should skip this row entirely.
        if (j == width)
            continue;
        else
            pivotColumn = j;
        
        // if we've made it here, then we have a new pivot location, and we're
        // tasked with clearing the rest of the row of nonzero entries.
        //
        // start by performing modular reduction on the column we care about.
        NSMutableArray *column = [ret.presentation objectAtIndex:pivotColumn];
        for (j = 0; j < height; j++)
            [column setObject:@([[column objectAtIndex:j] intValue] % 2)
                atIndexedSubscript:j];
        
        // then iterate through the other columns...
        for (j = 0; j < width; j++) {
            // skip the column we're working with, of course!
            if (j == pivotColumn)
                continue;
            if ([[column objectAtIndex:pivotRow] intValue] == 0)
                continue;
            
            NSMutableArray *workingColumn = [ret.presentation objectAtIndex:j];
            int factor = [[workingColumn objectAtIndex:pivotRow] intValue] /
                         [[column objectAtIndex:pivotRow] intValue];
            
            // ... and for each entry in this column, subtract.
            for (int i = 0; i < height; i++)
                [workingColumn
                    setObject:@(([[workingColumn objectAtIndex:i] intValue] -
                               factor * [[column objectAtIndex:i] intValue])%2)
                    atIndexedSubscript:i];
        }
        
        // prevent us from considering the same column twice.
        pivotColumn++;
    }

    return ret;
}

// returns a basis for the kernel of a matrix
-(NSMutableArray*) kernel {
    // vertically augment the matrix by an identity matrix
    EXTMatrix *augmentedMatrix = [self copy];
    [augmentedMatrix setHeight:(self.height + self.width)];
    
    for (int i = 0; i < self.width; i++) {
        NSMutableArray *column = [augmentedMatrix.presentation objectAtIndex:i];
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
        NSMutableArray *augmentedColumn =
            [reducedMatrix.presentation objectAtIndex:i];
        
        // test to see if the original column is full of zeroes
        bool skipme = false;
        for (int j = 0; j < self.height; j++)
            if ([[augmentedColumn objectAtIndex:j] intValue] != 0)
                skipme = true;
        if (skipme)   // if we found nonzero entries...
            continue; // ... skip this column.
        
        // otherwise, strip to the augmented portion
        NSArray *strippedColumn = [augmentedColumn subarrayWithRange:NSMakeRange(self.height, self.width)];
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
        [ret addObject:[[self presentation] objectAtIndex:i]];
    }
    
    return ret;
}

// returns the product of two matrices.
+(EXTMatrix*) newMultiply:(EXTMatrix*)left by:(EXTMatrix*)right {
    EXTMatrix *product = [EXTMatrix matrixWidth:[right width]
                                         height:[left height]];
    
    if (left.width != right.height)
        NSLog(@"Mismatched multiplication.");
    
    for (int k = 0; k < [right width]; k++) {
        NSMutableArray *rightColumn = [[right presentation] objectAtIndex:k],
                       *column = [NSMutableArray arrayWithCapacity:[left height]];
        for (int i = 0; i < [left height]; i++) {
            int total = 0;
            
            for (int j = 0; j < [left width]; j++)
                total += [[rightColumn objectAtIndex:j] intValue] *
                    [[[left.presentation objectAtIndex:j]
                      objectAtIndex:i] intValue];
            
            [column setObject:@(total) atIndexedSubscript:i];
        }
        
        [[product presentation] setObject:column atIndexedSubscript:k];
    }
    
    return product;
}

// matrix acts on a vector from the left.
-(NSMutableArray*) actOn:(NSMutableArray *)vector {
    EXTMatrix *tempMatrix = [EXTMatrix matrixWidth:1 height:vector.count];
    
    [tempMatrix.presentation setObject:vector atIndexedSubscript:0];
    
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
    for (int i = 0; i < self.width; i++) {
        [ret.presentation setObject:
            [unflip.presentation objectAtIndex:(self.width+i)]
                            atIndexedSubscript:i];
    }
    
    
    return ret;
}

-(int) rank {
    NSMutableArray *image = [self image];
    
    return image.count;
}

+(EXTMatrix*) assemblePresentation:(NSMutableArray*)partialDefinitions
                   sourceDimension:(int)sourceDimension
                   targetDimension:(int)targetDimension {
    NSArray *pair = [EXTMatrix assemblePresentationAndOptimize:partialDefinitions sourceDimension:sourceDimension targetDimension:targetDimension];
    
    return pair[0];
}

// returns a pair (EXTMatrix* presentation, NSMutableArray* partialDefinitions),
// where the right-hand term contains a minimal list of necessary partial def'ns
// used the generate this presentation.  good for paring these down.
+(NSArray*) assemblePresentationAndOptimize:(NSMutableArray*)partialDefinitions
                            sourceDimension:(int)sourceDimension
                            targetDimension:(int)targetDimension {
    // first, make sure we're not going to bomb.
    if (partialDefinitions.count == 0)
        return @[[EXTMatrix matrixWidth:sourceDimension height:targetDimension],[NSMutableArray array]];
    
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
                                             height:targetDimension];
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
        
        // if this vector is inessential, it will have been eliminated by rcef.
        if (isEmpty)
            continue;
        
        // if it's essential, we should add it. :)
        [minimalVectors addObject:imageVectors[i]];
        [minimalParents addObject:imageParents[i]];
        [minimalIndices addObject:imageIndices[i]];
    }
    
    /*
    // XXX: ideally we would set some kind of flag saying we were poorly defined
     
    // then, if we have too few vectors left to be of full rank...
    if (minimalVectors.count != sourceDimension)
        wellDefined = false; // ... then mark that we failed
    else
        wellDefined = true;  // ... otherwise, mark that we're good to go.
     */
    
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
    
    if (minimalVectors.count == 0)
        return @[[EXTMatrix matrixWidth:sourceDimension height:targetDimension],
                 [NSMutableArray array]];
    
    // and so here's our basis matrix.
    EXTMatrix *basisMatrix =
        [EXTMatrix matrixWidth:minimalVectors.count
                        height:[minimalVectors[0] count]];
    basisMatrix.presentation = minimalVectors;
    
    // now, we construct a matrix presenting the differential in this basis.
    // this is where the partial definitions actually get used.
    EXTMatrix *differentialInCoordinates =
            [EXTMatrix matrixWidth:basisMatrix.width height:targetDimension];
    for (int i = 0; i < basisMatrix.width; i++) {
        // if we're in the range of partially determined stuff, use the def'ns
        if (i < minimalParents.count) {
            EXTPartialDefinition *pdiffl =
                [partialDefinitions
                    objectAtIndex:[[minimalParents objectAtIndex:i] intValue]];
            EXTMatrix *diffl = [pdiffl differential];
            differentialInCoordinates.presentation[i] =
                [[diffl presentation]
                    objectAtIndex:[[minimalIndices objectAtIndex:i] intValue]];
        } else {
            // otherwise, extend by zero.
            NSMutableArray *workingColumn = [NSMutableArray array];
            
            for (int j = 0; j < basisMatrix.height; j++)
                [workingColumn setObject:@0 atIndexedSubscript:j];
            
            differentialInCoordinates.presentation[i] = workingColumn;
        }
    }
    
    // finally, we need to put these matrices together to build a presentation
    // of the differential in the standard basis.  this is simple: just invert
    // and multiply. :)
    EXTMatrix *basisConversion = [basisMatrix invert];
    EXTMatrix *stdDifferential =
        [EXTMatrix newMultiply:differentialInCoordinates by:basisConversion];
    
    // there is one last orthogonal task: returning a list of minimal def'ns
    NSMutableArray *minimalDefinitions = [NSMutableArray array];
    for (int index = 0; index < partialDefinitions.count; index++)
        if (([minimalParents indexOfObject:@(index)] != -1) &&
            ([minimalDefinitions indexOfObject:partialDefinitions[index]] != -1))
            [minimalDefinitions addObject:partialDefinitions[index]];
    
    // finally, all our hard work done, we jump back.
    return @[stdDifferential, minimalDefinitions];
}

// returns a scaled matrix
-(EXTMatrix*) scale:(int)scalar {
    EXTMatrix *ret = [self copy];
    
    for (int i = 0; i < ret.presentation.count; i++) {
        NSMutableArray *col = ret.presentation[i];
        for (int j = 0; j < col.count; j++)
            col[j] = @(scalar * [col[j] intValue]);
    }
    
    return ret;
}

// given a cospan A --> C <-- B, this routine forms the pullback span.
+(NSArray*) formIntersection:(EXTMatrix*)left with:(EXTMatrix*)right {
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
    EXTMatrix *ret = [EXTMatrix matrixWidth:a.width height:b.height];
    
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
        
        // haha, cool symbol garbage, (@"%@"
        NSLog(@"%@", output);
    }
}

@end
