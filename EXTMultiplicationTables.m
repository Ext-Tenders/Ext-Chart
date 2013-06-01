//
//  EXTMultiplicationTables.m
//  Ext Chart
//
//  Created by Eric Peterson on 5/19/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTMultiplicationTables.h"
#import "EXTterm.h"
#import "EXTdifferential.h"


@implementation EXTMultiplicationEntry
@synthesize presentation, partialDefinitions;

-(EXTMultiplicationEntry*) init {
    if (self = [super init]) {
        self.presentation = nil;
        self.partialDefinitions = [NSMutableArray array];
    }
    
    return self;
}

+(id) entry {
    return [EXTMultiplicationEntry new];
}

@end




@implementation EXTMultiplicationTables

@synthesize tables;
@synthesize sSeq;
@synthesize unitTerm;
@synthesize unitClass;

// XXX: general oversight: i don't check for when the target term exists.  this
// surely must get in the way sometimes...

-(id) init {
    if (!(self = [super init])) return nil;
    
    [self setTables:[NSMutableDictionary dictionary]];
    [self setSSeq:nil];
    [self setUnitTerm:nil];
    [self setUnitClass:[NSMutableArray array]];
    
    return self;
}

+(id) multiplicationTables:(EXTSpectralSequence *)sseq {
    EXTMultiplicationTables *ret = [EXTMultiplicationTables new];
    
    [ret setSSeq:sseq];
    
    return ret;
}

-(EXTMultiplicationEntry*) performLookup:(EXTLocation*)loc1
                                    with:(EXTLocation*)loc2 {
    // start by trying to pull the matrix out of the dictionary.
    NSString *key = [NSString stringWithFormat:@"%@ %@",
                     [loc1 description], [loc2 description]];
    EXTMultiplicationEntry *ret = [tables objectForKey:key];
    
    // find all the relevant EXTTerms, so we can calculate the right size
    Class<EXTLocation> locClass = [loc1 class];
    EXTTerm *term1 = [self.sSeq findTerm:loc1],
    *term2 = [self.sSeq findTerm:loc2],
    *targetterm = [self.sSeq findTerm:[locClass addLocation:loc1 to:loc2]];
    
    // if we can't find it, then we should instantiate it.
    if (!ret) {
        // instantiate the matrix
        ret = [EXTMultiplicationEntry entry];
        ret.presentation =
            [EXTMatrix matrixWidth:([term1 names].count * [term2 names].count)
                            height:[targetterm names].count];
        
        // and store it to the tables
        [tables setObject:ret forKey:key];
    }
    
    return ret;
}

-(void) addPartialDefinition:(EXTPartialDefinition*)partial
                          to:(EXTLocation*)loc1
                        with:(EXTLocation*)loc2 {
    EXTMultiplicationEntry *entry = [self performLookup:loc1 with:loc2];
    [entry.partialDefinitions addObject:partial];
    
    return;
}

// TODO: for the moment, note that this is order-sensitive.
-(EXTMatrix*) getMatrixFor:(EXTLocation*)loc1 with:(EXTLocation*)loc2 {
    EXTMultiplicationEntry *entry = [self performLookup:loc1 with:loc2];
    Class<EXTLocation> locClass = [loc1 class];
    EXTTerm *term1 = [self.sSeq findTerm:loc1],
    *term2 = [self.sSeq findTerm:loc2],
    *targetterm = [self.sSeq findTerm:[locClass addLocation:loc1 to:loc2]];
    
    int width, height;
    if (!term1 || !term2 || !targetterm) {
        width = height = 0;
    } else {
        width = [term1 names].count * [term2 names].count;
        height = [targetterm names].count;
    }
    
    entry.presentation = [EXTMatrix assemblePresentation:entry.partialDefinitions sourceDimension:width targetDimension:height];
    
    return entry.presentation;
}

// unsafe lookup
-(EXTMatrix*) getMatrixWithoutRecomputingFor:(EXTLocation*)loc1
                                        with:(EXTLocation*)loc2 {
    NSString *key = [NSString stringWithFormat:@"%@ %@",
                     [loc1 description], [loc2 description]];
    EXTMultiplicationEntry *ret = [tables objectForKey:key];
    
    return ret.presentation;
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
            [ret setObject:@([[vec1 objectAtIndex:i] intValue] *
                             [[vec2 objectAtIndex:j] intValue])
                 atIndexedSubscript:(vec1.count * i + j)];
    
    return ret;
}

// multiplies two classes together, according to the rules.
-(NSMutableArray *) multiplyClass:(NSMutableArray *)class1
                               at:(EXTLocation *)loc1
                             with:(NSMutableArray *)class2
                               at:(EXTLocation *)loc2 {
    // retrieve the multiplication rule
    EXTMatrix *productRule = [self getMatrixFor:loc1 with:loc2];
    
    // rewrite the pair of classes as something living in the tensor product
    NSMutableArray *hadamardVector =
                [EXTMultiplicationTables conglomerateVector:class1 with:class2];
    
    // and return the action.
    return [productRule actOn:hadamardVector];
}

-(void) computeLeibniz:(EXTLocation *)loc1
                  with:(EXTLocation *)loc2
                onPage:(int)page {
    // find a basis for the image of the product map, and select which vectors
    // we need to multiply to get them.
    EXTMatrix *product = [self getMatrixFor:loc1 with:loc2];
    NSMutableArray *image = [product image];
    
    // extract which columns contributed to the image of the product map
    NSMutableArray *indices = [NSMutableArray array];
    for (NSMutableArray *column in image) {
        for (int i = 0; i < product.presentation.count; i++) {
            bool isThisOne = true;
            for (int j = 0; j < [product.presentation[i] count]; j++) {
                if ([[[product.presentation objectAtIndex:i] objectAtIndex:j] intValue] != [[column objectAtIndex:j] intValue]) {
                    isThisOne = false;
                    
                    break;
                }
            }
            
            if (!isThisOne) // if the image col mismatched the working col...
                continue;   // then skip to the next working column.
            
            [indices addObject:@(i)]; // otherwise, add this index to the array
            break;                    // and skip to the next image column.
        }
    }
    
    // compute the action of the differentials on each factor in the
    // product decomposition: d(xy) = dx y + x dy.
    // XXX: deal with sign errors here.
    EXTLocation *sumloc = [[loc1 class] addLocation:loc1 to:loc2];
    EXTTerm *term1 = [self.sSeq findTerm:loc1],
            *term2 = [self.sSeq findTerm:loc2],
          *sumterm = [self.sSeq findTerm:sumloc];
    EXTDifferential *d1 = [self.sSeq findDifflWithSource:loc1 onPage:page],
                    *d2 = [self.sSeq findDifflWithSource:loc2 onPage:page];
    NSMutableArray *actions = [NSMutableArray array];
    
    for (NSNumber *hadamardPosition in indices) {
        int unwrappedPosition = [hadamardPosition intValue];
        
        // extract the actual en | fm pure tensor term
        int f = unwrappedPosition % [term1 names].count,
            e = unwrappedPosition - f * [term1 names].count;
        
        // assemble vectors expressing en and fm
        NSMutableArray *en = [NSMutableArray array];
        for (int i = 0; i < [term1 names].count; i++) {
            if (i == e)
                [en setObject:@(1) atIndexedSubscript:i];
            else
                [en setObject:@(0) atIndexedSubscript:i];
        }
        
        NSMutableArray *fm = [NSMutableArray array];
        for (int j = 0; j < [term2 names].count; j++) {
            if (j == f)
                [fm setObject:@(1) atIndexedSubscript:j];
            else
                [fm setObject:@(0) atIndexedSubscript:j];
        }
        
        // apply the differential matrices to them individually.
        // we have to be careful here --- missing differentials are implicit 0s.
        //
        // XXX: how do we know that these are up-to-date?  should EXTDiff'l
        // automatically try to compute a presentation when it's accessed?
        NSMutableArray *summand1 = [NSMutableArray array],
                       *summand2 = [NSMutableArray array];
        if (d1) {
            NSMutableArray *den = [[d1 presentation] actOn:en];
            summand1 = [self multiplyClass:den at:[d1 end].location
                                      with:fm at:loc2];
        } else
            for (int i = 0; i < sumterm.names.count; i++)
                [summand1 setObject:@(0) atIndexedSubscript:i];
        if (d2) {
            NSMutableArray *dfm = [[d2 presentation] actOn:fm];
            summand1 = [self multiplyClass:en at:loc1
                                      with:dfm at:[d2 end].location];
        } else
            for (int i = 0; i < sumterm.names.count; i++)
                [summand2 setObject:@(0) atIndexedSubscript:i];
        
        // sum and store to the list of actions.
        NSMutableArray *sum = [NSMutableArray array];
        for (int i = 0; i < summand1.count; i++)
            [sum setObject:@([[summand1 objectAtIndex:i] intValue] +
                             [[summand2 objectAtIndex:i] intValue])
                 atIndexedSubscript:i];
        
        [actions addObject:sum];
    }
    
    // store the array actions as the acting matrix for a partial definition.
    EXTDifferential *diffl = [self.sSeq findDifflWithSource:sumloc onPage:page];
    // if the differential we're trying to write to doesn't yet exist, build it.
    if (!diffl) {
        EXTTerm *targetterm = [self.sSeq findTerm:
                                 [[sumloc class] followDiffl:sumloc page:page]];
        diffl = [EXTDifferential differential:sumterm end:targetterm page:page];
        [[self.sSeq differentials] addObject:diffl];
    }
    
    // set up the partial definition matrices
    EXTPartialDefinition *partial = [EXTPartialDefinition new];
    EXTMatrix *differential = [EXTMatrix matrixWidth:actions.count
                                              height:[actions[0] count]],
              *inclusion = [EXTMatrix matrixWidth:actions.count
                                           height:[actions[0] count]];
    differential.presentation = image;
    inclusion.presentation = actions;
    partial.differential = differential;
    partial.inclusion = inclusion;
    
    // and, finally, add it to the list of partial definitions. :)
    [[diffl partialDefinitions] addObject:partial];
    
    return;
}

@end
