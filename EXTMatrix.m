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

@end
