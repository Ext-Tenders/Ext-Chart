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
    
    if (image.count == 0)
        return;
    
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
    EXTLocation *sumloc = [[loc1 class] addLocation:loc1 to:loc2],
             *targetLoc = [[loc1 class] followDiffl:sumloc page:page];
    EXTTerm *term1 = [self.sSeq findTerm:loc1],
            *term2 = [self.sSeq findTerm:loc2],
          *sumterm = [self.sSeq findTerm:sumloc],
       *targetterm = [self.sSeq findTerm:targetLoc];
    EXTDifferential *d1 = [self.sSeq findDifflWithSource:loc1 onPage:page],
                    *d2 = [self.sSeq findDifflWithSource:loc2 onPage:page];
    NSMutableArray *actions = [NSMutableArray array];
    
    // if we don't have differentials to work with, then skip this entirely.
    if (!sumterm || !targetterm || !d1 || !d2)
        return;
    
    // if we're here, then we have all the fixin's we need to construct some
    // more partial differential definitions.  let's find a place to put them.
    EXTDifferential *dsum = [self.sSeq findDifflWithSource:sumterm.location
                                                    onPage:page];
    if (!dsum) {
        dsum = [EXTDifferential differential:sumterm end:targetterm page:page];
        [sSeq.differentials addObject:dsum];
    }
    
    for (EXTPartialDefinition *partial1 in d1.partialDefinitions)
    for (EXTPartialDefinition *partial2 in d2.partialDefinitions) {
        // find the relevant multiplication laws
        EXTMultiplicationEntry
            *XBmults = [self performLookup:[[loc1 class] followDiffl:loc1 page:page] with:loc2],
            *AYmults = [self performLookup:loc1 with:[[loc2 class] followDiffl:loc2 page:page]];
        if (!XBmults || !AYmults)
            continue;
        
        // iterate through the partial multiplication definitions
        for (EXTPartialDefinition *XBmult in XBmults.partialDefinitions)
        for (EXTPartialDefinition *AYmult in AYmults.partialDefinitions) {
            // we have access to the differential cospans A <-< I --> X and
            // B <-< J --> Y, and to the multiplication cospans A|Y <-< K --> Z
            // and X|B <-< L --> Z.  define these so we have access to them.
            EXTMatrix *i = partial1.inclusion, *partialI = partial1.differential,
                      *j = partial2.inclusion, *partialJ = partial2.differential,
                      *k = AYmult.inclusion, *muK = AYmult.differential,
                      *l = XBmult.inclusion, *muL = XBmult.differential;
            
            // first, we'll produce the tensored up cospan A|B <-< I|B --> X|B.
            EXTMatrix *iId = [EXTMatrix hadamardProduct:i
                                            with:[EXTMatrix identity:j.height]],
               *partialIId = [EXTMatrix hadamardProduct:partialI
                                            with:[EXTMatrix identity:j.height]];
            
            // this shares a target to get A|B <-< I|B --> X|B <-< L --> Z, and
            // we take the intersection span to get a big cospan A|B <-< U --> Z
            NSArray *XBspan = [EXTMatrix formIntersection:partialIId with:l];
            EXTMatrix *u = [EXTMatrix newMultiply:iId by:XBspan[0]],
               *partialU = [EXTMatrix newMultiply:muL by:XBspan[1]];
            
            // then, do the same thing for A|B <-< A|J --> A|Y <-< K --> Z to
            // get a pulled back cospan A|B <-< V --> Z.
            EXTMatrix *Idj = [EXTMatrix hadamardProduct:[EXTMatrix identity:i.height] with:j],
               *IdpartialJ = [EXTMatrix hadamardProduct:[EXTMatrix identity:i.height] with:partialJ];
            NSArray *AYspan = [EXTMatrix formIntersection:IdpartialJ with:k];
            EXTMatrix *v = [EXTMatrix newMultiply:Idj by:AYspan[0]],
               *partialV = [EXTMatrix newMultiply:muK by:AYspan[1]];
            
            // lastly, take the intersection span of U >-> A|B <-< V to get a
            // shared subspace W, hence a pair of cospans both of the form
            // A|B <-< W --> Z.
            //
            // sum the two right-hand maps to get d(ab) = da*b + a*db.
            NSArray *ABspan = [EXTMatrix formIntersection:u with:v];
            EXTMatrix *w = [EXTMatrix newMultiply:u by:ABspan[0]],
               *partialW = [EXTMatrix
                            sum:[EXTMatrix newMultiply:partialU by:ABspan[0]]
                            with:[EXTMatrix newMultiply:partialV by:ABspan[1]]];
            
            // store this to a list of partial definitions.
            EXTPartialDefinition *partial = [EXTPartialDefinition new];
            partial.inclusion = w; partial.differential = partialW;
            [dsum.partialDefinitions addObject:partial];
        }
    }
    
    return;
}

@end
