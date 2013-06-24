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


@interface EXTMultiplicationKey : NSObject <NSCopying>
@property(strong) EXTLocation *left;
@property(strong) EXTLocation *right;
+(EXTMultiplicationKey*) newWith:(EXTLocation*)left and:(EXTLocation*)right;
-(NSUInteger) hash;
@end

@implementation EXTMultiplicationKey
@synthesize left, right;
+(EXTMultiplicationKey*) newWith:(EXTLocation*)newLeft
                             and:(EXTLocation*)newRight {
    EXTMultiplicationKey *ret = [EXTMultiplicationKey new];
    ret.left = [newLeft copy]; ret.right = [newRight copy];
    return ret;
}
-(BOOL) isEqual:(id)object {
    if ([object class] != [EXTMultiplicationKey class])
        return false;
    EXTMultiplicationKey *input = (EXTMultiplicationKey*)object;
    
    return ([self.left isEqual:input.left] && [self.right isEqual:input.right]);
}
-(EXTMultiplicationKey*) copyWithZone:(NSZone*)zone {
    EXTMultiplicationKey *ret = [[EXTMultiplicationKey allocWithZone:zone] init];
    ret.left = [self.left copyWithZone:zone];
    ret.right = [self.right copyWithZone:zone];
    return ret;
}

- (NSUInteger) hash {
	long long key = [left hash];
	key = (~key) + (key << 18); // key = (key << 18) - key - 1;
    key += [right hash];
	key = key ^ (key >> 31);
	key = key * 21; // key = (key + (key << 2)) + (key << 4);
	key = key ^ (key >> 11);
	key = key + (key << 6);
	key = key ^ (key >> 22);
	return (int) key;
}
@end


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



// TODO: possibly this should be a subclass of some interface along the lines of
// EXTMultiplicativeStructure.  that might give us the flexibility to implement
// fast specific versions, like pure polynomial algebras, and also compensate
// for things like a Steenrod algebra action.
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

// this performs a lookup without instantiating a new entry if it's not found.
-(EXTMultiplicationEntry*) performSoftLookup:(EXTLocation*)loc1
                                        with:(EXTLocation*)loc2 {
    // start by trying to pull the matrix out of the dictionary.
    return [tables objectForKey:[EXTMultiplicationKey newWith:loc1 and:loc2]];
}

-(EXTMultiplicationEntry*) performLookup:(EXTLocation*)loc1
                                    with:(EXTLocation*)loc2 {
    EXTMultiplicationEntry *ret = [self performSoftLookup:loc1 with:loc2];
    
    // if we can't find it, then we should instantiate it.
    if (!ret) {
        // find all the relevant EXTTerms, so we can calculate the right size
        Class<EXTLocation> locClass = [loc1 class];
        EXTTerm *term1 = [self.sSeq findTerm:loc1],
                *term2 = [self.sSeq findTerm:loc2],
           *targetterm = [self.sSeq findTerm:[locClass addLocation:loc1 to:loc2]];
        
        // instantiate the matrix
        ret = [EXTMultiplicationEntry entry];
        ret.presentation =
            [EXTMatrix matrixWidth:([term1 names].count * [term2 names].count)
                            height:[targetterm names].count];
        
        // and store it to the tables
        [tables setObject:ret forKey:[EXTMultiplicationKey newWith:loc1 and:loc2]];
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

-(void) naivelyPropagateLeibniz:(EXTLocation*)loc page:(int)page {
    // once we have those, we should be able to do the rest.
    for (EXTTerm *t in sSeq.terms.allValues)
        [self computeLeibniz:loc with:t.location onPage:page];
    
    return;
}

// propagates differentials along a specified lattice of EXTLocations
-(void) propagateLeibniz:(NSArray*)locations page:(int)page {
    NSMutableArray *maxes = [NSMutableArray arrayWithCapacity:locations.count];
    Class<EXTLocation> locClass = [(EXTLocation*)locations[0] class];
    
    // build the array of maximums
    for (int i = 0; i < locations.count; i++) {
        EXTLocation *loc = locations[i];
        for (int j = 1; true; j++) {
            EXTTerm *t = [sSeq findTerm:loc];
            
            if (!t) {
                maxes[i] = @(j);
                break;
            }
            
            loc = [[loc class] addLocation:loc to:locations[i]];
        }
    }
    
    // loop through the available differentials by incrementing an array of
    // counters.  the idea is that the counter [n0, n1, ..., nm, 0, ..., 0]
    // corresponds to the product [n0, ..., nm-1, 0, ..., 0] * em.
    NSMutableArray *counter = [NSMutableArray arrayWithCapacity:locations.count];
    for (int i = 0; i < locations.count; i++)
        counter[i] = @0;
    counter[0] = @1;
    int digitalSum = 1;
    while (true) {
        // increment the counter array
        for (int i = 0; i < locations.count; i++) {
            counter[i] = @([counter[i] intValue] + 1);
            
            // check if we should perform a carry
            if ([counter[i] isEqual:maxes[i]]) {
                counter[i] = @0;
                // and then the for(i) loop will handle the actual carry
            } else
                break;
        }
        
        // calculate the digital sum
        digitalSum = 0;
        for (int i = 0; i < locations.count; i++)
            digitalSum += [counter[i] intValue];
        
        // this dictates the two edge cases.  if the counter array has only one
        // thing in it, then we don't have enough to perform a leibniz
        // calculation, and we should skip ahead to the next counter.
        if (digitalSum == 1)
            continue;
        // and if we've completely rolled over, we're done, so break and return.
        else if (digitalSum == 0)
            break;
        
        // otherwise, if we have a digital sum >= 2, then find the topmost
        // nonzero entry, and think of this as what we're propagating against.
        int topEntry = locations.count-1;
        for (; topEntry >= 0; topEntry--)
            if ([counter[topEntry] intValue] != 0)
                break;
        
        // build the EXTLocation sum corresponding to the vector coordinate
        EXTLocation *leftLoc = [locClass identityLocation];
        for (int i = 0; i < topEntry; i++)
            leftLoc = [locClass addLocation:leftLoc to:[locClass scale:locations[i] by:[counter[i] intValue]]];
        leftLoc = [locClass addLocation:leftLoc to:[locClass scale:locations[topEntry] by:([counter[topEntry] intValue]-1)]];
                
        // call -computeLeibniz on (the previous sum + the shifted coordinate)
        [self computeLeibniz:leftLoc with:locations[topEntry] onPage:page];
    }
    
    return;
}

// compute the action of the differentials on each factor in the product
// decomposition: d(xy) = dx y + x dy.
-(void) computeLeibniz:(EXTLocation *)loc1
                  with:(EXTLocation *)loc2
                onPage:(int)page {
    EXTLocation *sumLoc = [[loc1 class] addLocation:loc1 to:loc2],
             *targetLoc = [[loc1 class] followDiffl:sumLoc page:page];
    EXTTerm *sumterm = [self.sSeq findTerm:sumLoc],
         *targetterm = [self.sSeq findTerm:targetLoc],
                  *A = [self.sSeq findTerm:loc1],
                  *B = [self.sSeq findTerm:loc2];
    EXTDifferential *d1 = [self.sSeq findDifflWithSource:loc1 onPage:page],
                    *d2 = [self.sSeq findDifflWithSource:loc2 onPage:page];
    
    // if we don't have differentials to work with, then skip this entirely.
    // XXX: i'm not sure this condition is quite right.
    BOOL d1Zero = [sSeq isInZeroRanges:[[loc1 class] followDiffl:loc1 page:page]],
         d2Zero = [sSeq isInZeroRanges:[[loc2 class] followDiffl:loc2 page:page]];
    if ((!d1 && !d1Zero) ||
        (!d2 && !d2Zero) ||
        !targetterm ||
        [sSeq isInZeroRanges:sumLoc] ||
        !sumterm ||
        [sSeq isInZeroRanges:targetLoc])
        return;
        
    // if we're here, then we have all the fixin's we need to construct some
    // more partial differential definitions.  let's find a place to put them.
    EXTDifferential *dsum = [self.sSeq findDifflWithSource:sumterm.location
                                                    onPage:page];
    if (!dsum) {
        dsum = [EXTDifferential differential:sumterm end:targetterm page:page];
        [sSeq.differentials addObject:dsum];
    }
    
    // depending upon whether a differential lands in the zero range, we need to
    // take various actions.  TODO: it would be great if there were some way of
    // silently propagating a default 'zero value', but this seems really hard
    // when getting, like, domains and ranges to line up properly.  if i had
    // encapsulated vectors into a class instead of just using NSMutableArray's,
    // it might be possible, but as it stands it's really uncomfortable.
    //
    // XXX: in the meantime, this contains a lot of duplicated code. mea culpa.
    if (d1Zero && d2Zero) {
        // in the case that both differentials are zero, no matter what happens
        // we're going to end up with the zero differential off the source.
        EXTPartialDefinition *allZero = [EXTPartialDefinition new];
        allZero.inclusion = [EXTMatrix identity:sumterm.names.count];
        allZero.differential = [EXTMatrix matrixWidth:sumterm.names.count
                                               height:targetterm.names.count];
        [dsum.partialDefinitions addObject:allZero];
    } else if (d1Zero && !d2Zero) {
        for (EXTPartialDefinition *partial2 in d2.partialDefinitions) {
            // find the relevant multiplication laws
            EXTMultiplicationEntry *AYmults = [self performSoftLookup:loc1 with:[[loc2 class] followDiffl:loc2 page:page]];
            if (!AYmults)
                continue;
            
            // iterate through the partial multiplication definitions
            for (EXTPartialDefinition *AYmult in AYmults.partialDefinitions) {
                // we have access to the differential cospan B <-< J --> Y and
                // to the multiplication cospan A|Y <-< K --> Z.  define these
                // so we have access to them.
                EXTMatrix
                    *j = partial2.inclusion, *partialJ = partial2.differential,
                    *k = AYmult.inclusion, *muK = AYmult.differential;
                
                // from A|B <-< A|J --> A|Y <-< K --> Z, build the pullback
                // cospan A|B <-< V --> Z.
                EXTMatrix
                    *Idj = [EXTMatrix hadamardProduct:[EXTMatrix identity:A.names.count] with:j],
                    *IdpartialJ = [EXTMatrix hadamardProduct:[EXTMatrix identity:A.names.count] with:partialJ];
                NSArray *AYspan = [EXTMatrix formIntersection:IdpartialJ with:k];
                EXTMatrix *v = [EXTMatrix newMultiply:Idj by:AYspan[0]],
                *partialV = [EXTMatrix newMultiply:muK by:AYspan[1]];
                        
                // store this to a list of partial definitions.
                EXTPartialDefinition *partial = [EXTPartialDefinition new];
                partial.inclusion = v; partial.differential = partialV;
                [dsum.partialDefinitions addObject:partial];
            }
        }
    } else if (!d1Zero && d2Zero) {
        for (EXTPartialDefinition *partial1 in d1.partialDefinitions) {
            // find the relevant multiplication laws
            EXTMultiplicationEntry *XBmults = [self performSoftLookup:[[loc1 class] followDiffl:loc1 page:page] with:loc2];
            if (!XBmults)
                continue;
            
            // iterate through the partial multiplication definitions
            for (EXTPartialDefinition *XBmult in XBmults.partialDefinitions) {
                // we have access to the differential cospans A <-< I --> X and
                // B <-< J --> Y, and to the multiplication cospans
                // A|Y <-< K --> Z and X|B <-< L --> Z.  define these so we have
                // access to them.
                EXTMatrix
                    *i = partial1.inclusion, *partialI = partial1.differential,
                    *l = XBmult.inclusion, *muL = XBmult.differential;
                        
                // first, produce the tensored up cospan A|B <-< I|B --> X|B.
                EXTMatrix
                    *iId = [EXTMatrix hadamardProduct:i with:[EXTMatrix identity:B.names.count]],
                    *partialIId = [EXTMatrix hadamardProduct:partialI with:[EXTMatrix identity:B.names.count]];
                        
                // this shares a target to get A|B <-< I|B --> X|B <-< L --> Z,
                // so intersect to get a big cospan A|B <-< U --> Z.
                NSArray *XBspan = [EXTMatrix formIntersection:partialIId with:l];
                EXTMatrix *u = [EXTMatrix newMultiply:iId by:XBspan[0]],
                        *partialU = [EXTMatrix newMultiply:muL by:XBspan[1]];
                        
                // store this to a list of partial definitions.
                EXTPartialDefinition *partial = [EXTPartialDefinition new];
                partial.inclusion = u; partial.differential = partialU;
                [dsum.partialDefinitions addObject:partial];
            }
        }
    } else {
        for (EXTPartialDefinition *partial1 in d1.partialDefinitions)
        for (EXTPartialDefinition *partial2 in d2.partialDefinitions) {
            // find the relevant multiplication laws
            EXTMultiplicationEntry
                *XBmults = [self performSoftLookup:[[loc1 class] followDiffl:loc1 page:page] with:loc2],
                *AYmults = [self performSoftLookup:loc1 with:[[loc2 class] followDiffl:loc2 page:page]];
            if (!XBmults || !AYmults)
                continue;
            
            // iterate through the partial multiplication definitions
            for (EXTPartialDefinition *XBmult in XBmults.partialDefinitions)
            for (EXTPartialDefinition *AYmult in AYmults.partialDefinitions) {
                // we have access to the differential cospans A <-< I --> X and
                // B <-< J --> Y, and to the multiplication cospans
                // A|Y <-< K --> Z and X|B <-< L --> Z.  define these so we have
                // access to them.
                EXTMatrix
                    *i = partial1.inclusion, *partialI = partial1.differential,
                    *j = partial2.inclusion, *partialJ = partial2.differential,
                    *k = AYmult.inclusion, *muK = AYmult.differential,
                    *l = XBmult.inclusion, *muL = XBmult.differential;
                        
                // first, produce the tensored up cospan A|B <-< I|B --> X|B.
                EXTMatrix
                    *iId = [EXTMatrix hadamardProduct:i with:[EXTMatrix identity:j.height]],
                    *partialIId = [EXTMatrix hadamardProduct:partialI with:[EXTMatrix identity:j.height]];
                        
                // this shares a target to get A|B <-< I|B --> X|B <-< L --> Z,
                // so intersect to get a big cospan A|B <-< U --> Z.
                NSArray *XBspan = [EXTMatrix formIntersection:partialIId with:l];
                EXTMatrix *u = [EXTMatrix newMultiply:iId by:XBspan[0]],
                        *partialU = [EXTMatrix newMultiply:muL by:XBspan[1]];
                        
                // then, do the same thing for A|B <-< A|J --> A|Y <-< K --> Z
                // to get a pulled back cospan A|B <-< V --> Z.
                EXTMatrix
                    *Idj = [EXTMatrix hadamardProduct:[EXTMatrix identity:i.height] with:j],
                    *IdpartialJ = [EXTMatrix hadamardProduct:[EXTMatrix identity:i.height] with:partialJ];
                NSArray *AYspan = [EXTMatrix formIntersection:IdpartialJ with:k];
                EXTMatrix *v = [EXTMatrix newMultiply:Idj by:AYspan[0]],
                *partialV = [EXTMatrix newMultiply:muK by:AYspan[1]];
                        
                // lastly, take the intersection span of U >-> A|B <-< V to get
                // a shared subspace W, hence a pair of cospans both of the form
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
    }
    
    [dsum stripDuplicates];
    
    return;
}

@end
