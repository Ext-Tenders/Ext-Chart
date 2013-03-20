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
    EXTMatrix *object = [EXTMatrix alloc];
    
    // set the basic properties
    [object setHeight:newHeight];
    [object setWidth:newWidth];
    
    // allocate the matrix
    NSMutableArray *matrix = [[NSMutableArray alloc]
                              initWithCapacity:[object width]];
    for (int j = 0; j < [object height]; j++) {
        [matrix setObject:[[NSMutableArray alloc]
                           initWithCapacity:[object height]]
            atIndexedSubscript:j];
    }
    
    // ... and store the matrix.
    [object setPresentation:matrix];
    
    return object;
}

// if we're released, release the matrix we're holding onto too.
-(void) dealloc {
    [presentation dealloc];
    
    [super dealloc];
}

// allocates and initializes a new matrix 
+(EXTMatrix*) transpose:(EXTMatrix *)input {
    EXTMatrix *ret = [EXTMatrix initWithWidth:[input height]
                                    andHeight:[input width]];
    
    for (int i = 0; i < [input height]; i++) {
        NSMutableArray *newColumn = [[NSMutableArray alloc] initWithCapacity:[input height]];
        
        for (int j = 0; j < [input width]; j++) {
            // read off the subscripts in the inverse order
            [newColumn setObject:[[[input presentation] objectAtIndex:j] objectAtIndex:i] atIndexedSubscript:j];
        }
        
        [[ret presentation] setObject:newColumn atIndexedSubscript:i];
    }
    
    // XXX: should this be [ret autorelease] ?
    return ret;
}

// replaces all the elements of a matrix with their reductions mod 2
-(void) modularReduction {
    for (int i = 0; i < [self width]; i++) {
        NSMutableArray *column = [presentation objectAtIndex:i];
        
        for (int j = 0; j < [self height]; j++) {
            [column setObject:((int)[column objectAtIndex:j] % 2)
                    atIndexedSubscript:j];
        }
    }
}

// runs gaussian column reduction on a matrix.  useful of course for finding
// a presentation of the image of a matrix.
-(EXTMatrix*) columnReduce {
    EXTMatrix *ret = [self copy];
    int pivotRow = 0, pivotColumn = 0;
    
    for (pivotRow = 0; (pivotRow < height) && (pivotColumn < width);
         pivotRow++) {
        
        int j;
        
        // find the first nonzero entry in this row, right of where we're at
        for (j = pivotColumn; j < width; j++) {
            if (0 != [[presentation objectAtIndex:j] objectAtIndex:pivotRow])
                break;
        }
        
        // if we found a nonzero entry, then this is the new pivot column.
        // if we didn't, then we should skip this row entirely.
        if ([[presentation objectAtIndex:j] objectAtIndex:pivotRow] != 0)
            pivotColumn = j;
        else
            continue;
        
        // if we've made it here, then we have a new pivot location, and we're
        // tasked with clearing the rest of the row of nonzero entries.
        //
        // start by performing modular reduction on the column we care about.
        NSMutableArray *column = [presentation objectAtIndex:pivotColumn];
        for (j = 0; j < height; j++)
            [column setObject:((int)[column objectAtIndex:j] % 2)
                atIndexedSubscript:j];
        
        // then iterate through the other columns...
        for (j = 0; j < width; j++) {
            NSMutableArray *workingColumn = [presentation objectAtIndex:j];
            int factor = (int)[workingColumn objectAtIndex:pivotRow] /
                         (int)[column objectAtIndex:pivotRow];
            
            // ... and for each entry in this column, subtract.
            for (int i = 0; i < height; i++)
                [workingColumn
                    setObject:((int)[workingColumn objectAtIndex:i] -
                               factor * (int)[column objectAtIndex:i])
                    atIndexedSubscript:i];
        }
        
        // prevent us from considering the same column twice.
        pivotColumn++;
    }
    
    return ret;
}

// returns a basis for the kernel of a matrix
-(NSMutableArray*) kernel {
    EXTMatrix *transpose = [EXTMatrix transpose:self];
    
    // XXX: is this necessary?  is it even valid?
    [transpose autorelease];
    
    return [transpose image];
}

// returns a basis for the cokernel of a matrix
-(NSMutableArray*) image {
    EXTMatrix *reduced = [self columnReduce];
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    
    // iterate through the columns
    for (int i = 0; i < [reduced width]; i++) {
        NSMutableArray *column = [[reduced presentation] objectAtIndex:i];
        
        // test to see if the column is not all zeroes
        bool skipit = true;
        for (int j = 0; j < [column count]; j++)
            if ([column objectAtIndex:j] != 0)
                skipit = false;
        
        if (skipit)   // it's all zeroes...
            continue; // so skip it.
        
        // and, if it's not all zeroes, we should add it to the collection.
        [ret addObject:column];
    }
    
    [reduced release];
    return ret;
}

+(EXTMatrix*) multiply:(EXTMatrix*)left by:(EXTMatrix*)right {
    EXTMatrix *product = [EXTMatrix initWithWidth:[right width]
                                        andHeight:[left height]];
    
    for (int k = 0; k < [right width]; k++) {
        NSMutableArray *rightColumn = [[right presentation] objectAtIndex:k],
                       *column = [[NSMutableArray alloc]
                                  initWithCapacity:[left height]];
        for (int i = 0; i < [left height]; i++) {
            int total = 0;
            
            for (int j = 0; j < [left width]; j++)
                total += (int)[column objectAtIndex:j] *
                    (int)[[[left presentation] objectAtIndex:i] objectAtIndex:j];
            
            [column setObject:total atIndexedSubscript:i];
        }
        
        [[product presentation] setObject:column atIndexedSubscript:k];
    }
    
    // XXX: again, autorelease??
    return product;
}

// debug routine to dump the matrix to the console.
-(void) log {
    for (int i = 0; i < width; i++) {
        NSString *output = @"";
        
        for (int j = 0; j < height; j++) {
            output = [output stringByAppendingFormat:@"%d, ",
                      (int)[[presentation objectAtIndex:i] objectAtIndex:j]];
        }
        
        // haha, cool symbol garbage, (@"%@"
        NSLog(@"%@", output);
    }
}

@end
