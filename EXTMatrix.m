//
//  EXTMatrix.m
//  Ext Chart
//
//  Created by Eric Peterson on 3/16/13.
//  Copyright (c) 2013 HLProducts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EXTMatrix.h"

@implementation EXTMatrix

@synthesize height, width;
@synthesize presentation;

// initializes an EXTMatrix object and allocates all the NSMutableArrays
// used in the presentation.
+(EXTMatrix*) initWithWidth:(int)newWidth andHeight:(int)newHeight {
    EXTMatrix *obj = [[EXTMatrix alloc] init];
    
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

-(EXTMatrix*) matrixWithWidth:(int)newWidth andHeight:(int)newHeight {
    EXTMatrix *object = [EXTMatrix initWithWidth:newWidth andHeight:newHeight];
    
    [object autorelease];
    
    return object;
}

// allocates and initializes a new matrix 
+(EXTMatrix*) copyTranspose:(EXTMatrix *)input {
    EXTMatrix *ret = [EXTMatrix initWithWidth:input.height
                                    andHeight:input.width];
    
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

// performs a *deep* copy of the matrix
-(EXTMatrix*) copy {
    EXTMatrix *copy = [EXTMatrix initWithWidth:width andHeight:height];
    
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            NSNumber *num = [[[presentation objectAtIndex:i]
                              objectAtIndex:j] copy];
            [[copy.presentation objectAtIndex:i] setObject:num
                                        atIndexedSubscript:j];
        }
    }
    
    return copy;
}

// runs gaussian column reduction on a matrix.  useful of course for finding
// a presentation of the image of a matrix.
-(EXTMatrix*) columnReduce {
    int pivotRow = 0, pivotColumn = 0;
    EXTMatrix *ret = [self copy];
    
    for (pivotRow = 0; (pivotRow < height) && (pivotColumn < width);
         pivotRow++) {
        
        int j;
        
        // find the first nonzero entry in this row, right of where we're at
        for (j = pivotColumn; j < width; j++) {
            if (0 != [[[ret.presentation objectAtIndex:j]
                       objectAtIndex:pivotRow] intValue])
                break;
        }
        
        // if we found a nonzero entry, then this is the new pivot column.
        // if we didn't, then we should skip this row entirely.
        if (0 != [[[ret.presentation objectAtIndex:j]
                   objectAtIndex:pivotRow] intValue])
            pivotColumn = j;
        else
            continue;
        
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
            
            NSMutableArray *workingColumn = [ret.presentation objectAtIndex:j];
            int factor = [[workingColumn objectAtIndex:pivotRow] intValue] /
                         [[column objectAtIndex:pivotRow] intValue];
            
            // ... and for each entry in this column, subtract.
            for (int i = 0; i < height; i++)
                [workingColumn
                    setObject:@([[workingColumn objectAtIndex:i] intValue] -
                               factor * [[column objectAtIndex:i] intValue])
                    atIndexedSubscript:i];
        }
        
        // prevent us from considering the same column twice.
        pivotColumn++;
    }
    
    [ret autorelease];
    return ret;
}

// returns a basis for the kernel of a matrix
-(NSMutableArray*) kernel {
    // vertically augment the matrix by an identity matrix
    EXTMatrix *augmentedMatrix = [self copy];
    [augmentedMatrix setHeight:(self.height + self.width)];
    
    for (int i = 0; i < self.width; i++) {
        NSMutableArray *column = [augmentedMatrix.presentation objectAtIndex:i];
        for (int j = 0; j < self.height; j++) {
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
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    
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
        [ret addObject:column];
    }
    
    [ret autorelease];
    
    return ret;
}

+(EXTMatrix*) newMultiply:(EXTMatrix*)left by:(EXTMatrix*)right {
    EXTMatrix *product = [EXTMatrix initWithWidth:[right width]
                                        andHeight:[left height]];
    
    for (int k = 0; k < [right width]; k++) {
        NSMutableArray *rightColumn = [[right presentation] objectAtIndex:k],
                       *column = [NSMutableArray arrayWithCapacity:[left height]];
        for (int i = 0; i < [left height]; i++) {
            int total = 0;
            
            for (int j = 0; j < [left width]; j++)
                total += [[rightColumn objectAtIndex:j] intValue] *
                    [[[left.presentation objectAtIndex:i]
                      objectAtIndex:j] intValue];
            
            [column setObject:@(total) atIndexedSubscript:i];
        }
        
        [[product presentation] setObject:column atIndexedSubscript:k];
    }
    
    return product;
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
