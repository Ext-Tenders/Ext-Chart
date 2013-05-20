//
//  EXTMultiplicationTables.m
//  Ext Chart
//
//  Created by Eric Peterson on 5/19/13.
//  Copyright (c) 2013 HLProducts. All rights reserved.
//

#import "EXTMultiplicationTables.h"
#import "EXTterm.h"

@implementation EXTMultiplicationTables

@synthesize tables;
@synthesize document;

-(id) init {
    [super init];
    
    [self setTables:[NSMutableDictionary dictionary]];
    [self setDocument:nil];
    
    return self;
}

+(id) multiplicationTables:(EXTDocument *)document {
    EXTMultiplicationTables *ret = [[EXTMultiplicationTables alloc] init];
    
    [ret setDocument:document];
    
    return [ret autorelease];
}

// TODO: for the moment, note that this is order-sensitive.
-(EXTMatrix*) getMatrixFor:(EXTPair *)loc1 with:(EXTPair *)loc2 {
    // start by trying to pull the matrix out of the dictionary.
    NSString *key = [NSString stringWithFormat:@"%@ %@",
                     [loc1 description], [loc2 description]];
    EXTMatrix *ret = [tables objectForKey:key];
    
    // if we can't find it, then we should instantiate it.
    if (!ret) {
        // find all the relevant EXTTerms, so we can calculate the right size
        EXTTerm *term1 = [document findTerm:loc1],
                *term2 = [document findTerm:loc2],
           *targetterm = [document findTerm:[EXTPair addPairs:loc1 to:loc2]];
        
        // instantiate the matrix
        ret = [EXTMatrix matrixWidth:([term1 names].count * [term2 names].count)
                              height:[targetterm names].count];
        
        // and store it to the tables
        [tables setValue:ret forKey:key];
    }

    return ret;
}

// return the hadamard product, so to speak, of two vectors.
+(NSMutableArray*) conglomerateVector:(NSMutableArray*)vec1
                                 with:(NSMutableArray*)vec2 {
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:
                                          (vec1.count * vec2.count)];
    
    // (e1 + e2) | (f1 + f2) gets sent to e1|f1 + e1|f2 + e2|f1 + e2|f2,
    // using dictionary ordering in the two slots.
    for (int i = 0; i < vec1.count; i++)
        for (int j = 0; j < vec2.count; j++)
            [ret setObject:([[vec1 objectAtIndex:i] intValue] *
                            [[vec2 objectAtIndex:j] intValue])
                 atIndexedSubscript:@(vec1.count * i + j)];
    
    return ret;
}

// multiplies two classes together, according to the rules.
-(NSMutableArray *) multiplyClass:(NSMutableArray *)class1 at:(EXTPair *)loc1
                             with:(NSMutableArray *)class2 at:(EXTPair *)loc2 {
    // retrieve the multiplication rule
    EXTMatrix *productRule = [self getMatrixFor:loc1 with:loc2];
    
    // rewrite the pair of classes as something living in the tensor product
    NSMutableArray *hadamardVector =
                [EXTMultiplicationTables conglomerateVector:class1 with:class2];
    
    // and return the action.
    return [productRule actOn:hadamardVector];
}

@end
