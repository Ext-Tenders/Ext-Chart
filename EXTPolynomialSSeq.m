//
//  EXTPolynomialSSeq.m
//  Ext Chart
//
//  Created by Eric Peterson on 7/6/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTPolynomialSSeq.h"
#import "EXTTerm.h"
#import "EXTDifferential.h"


// EXTTerms should have names which aren't strings but "tags".  each tag should
// be either a dictionary of pairs of base class + exponent.  multiplication
// should act by iterating through and adding these lists together.
//
// for robustness, a nil entry in a tag should be thought of as zero, so that
// when introducing a new class we don't have to go back and add a bunch of
// labels to the existing tags.
@implementation EXTPolynomialTag

@synthesize tags;

-(EXTPolynomialTag*) init {
    if (self = [super init]) {
        tags = [NSMutableDictionary dictionary];
    }
    
    return self;
}

// sends the tag dictionary [[x, 1], [y, 2]] to the string "x^1 y^2"
-(NSString*) description {
    NSString *ret = [NSMutableString string];
    
    for (NSString *key in tags.keyEnumerator) {
        ret = [ret stringByAppendingFormat:@" (%@)^{%@}", key.description, [tags objectForKey:key]];
    }
    
    return ret;
}

+(EXTPolynomialTag*) sum:(EXTPolynomialTag*)left with:(EXTPolynomialTag*)right {
    EXTPolynomialTag *ret = [left copy];
    
    for (NSString *key in right.tags.keyEnumerator) {
        id leftValue = [left.tags objectForKey:key],
            rightValue = [right.tags objectForKey:key];
        if (!leftValue)
            [ret.tags setObject:rightValue forKey:key];
        else
            [ret.tags setObject:@([rightValue intValue] + [leftValue intValue]) forKey:key];
    }
    
    return ret;
}

-(BOOL) isEqual:(id)object {
    if ([object class] != [EXTPolynomialTag class])
        return FALSE;
    
    EXTPolynomialTag *target = (EXTPolynomialTag*)object;
    
    for (NSString *key in target.tags.keyEnumerator) {
        int value = [[target.tags objectForKey:key] intValue];
        if (value == 0)
            continue;
        NSNumber *selfValue = [tags objectForKey:key];
        if (!selfValue)
            return FALSE;
        if ([selfValue intValue] != value)
            return FALSE;
    }
    
    for (NSString *key in tags.keyEnumerator) {
        int value = [[tags objectForKey:key] intValue];
        if (value == 0)
            continue;
        NSNumber *targetValue = [target.tags objectForKey:key];
        if (!targetValue)
            return FALSE;
        if ([targetValue intValue] != value)
            return FALSE;
    }
    
    return TRUE;
}

-(id) copyWithZone:(NSZone *)zone {
    EXTPolynomialTag *ret = [EXTPolynomialTag new];
    ret.tags = [NSMutableDictionary dictionaryWithDictionary:tags];
    return ret;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        tags = [aDecoder decodeObjectForKey:@"tags"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:tags forKey:@"tags"];
}

@end



//
// now, the actual polynomial spectral sequence class.
//
@implementation EXTPolynomialSSeq

@synthesize generators;

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        generators = [aDecoder decodeObjectForKey:@"generators"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:generators forKey:@"generators"];
}

-(EXTMultiplicationTables*) multTables {
    NSLog(@"EXTPolynomialSSeq %@ was asked for its multTables.", self);
    return nil;
}

// blank out the new member variables
-(EXTPolynomialSSeq*) init {
    self = [super init];
    
    generators = [NSMutableArray array];
    
    return self;
}

-(EXTPolynomialSSeq*) initWithUnit:(Class<EXTLocation>)locClass {
    self = [super init];
    
    // TODO: it's weird to me to have this code in two adjacent places, but i
    // can't think of a way around this that doesn't run into problems with
    // polymorphism.  like, for instance, suppose that self is actually of class
    // EXTMaySpectralSequence; it calls init on itself, which then calls init
    // on super, which winds up here.  we can't call init on self to pull in the
    // code from the routine above this one, since that will just cause a big
    // loop back down to EXTMaySpectralSequence. i don't know. it's complicated.
    generators = [NSMutableArray array];
    
    self.indexClass = locClass;
    
    EXTTerm *unit = [EXTTerm term:[locClass identityLocation] andNames:[NSMutableArray arrayWithObject:@"1"]];
    [self.terms setObject:unit forKey:unit.location];
    
    return self;
}

// return an almost-empty spectral sequence
+(EXTPolynomialSSeq*) sSeqWithUnit:(Class<EXTLocation>)locClass {
    EXTPolynomialSSeq *ret = [EXTPolynomialSSeq new];
    
    ret.indexClass = locClass;
    
    EXTTerm *unit = [EXTTerm term:[locClass identityLocation] andNames:[NSMutableArray arrayWithObject:@"1"]];
    [ret.terms setObject:unit forKey:unit.location];
    
    return ret;
}

// performs an irreversible upcast
// XXX: these copies may not be deep enough to prevent modifications of the
// return value independent of the parent polynomial spectral sequence.  so,
// this should be considered a DESTRUCTIVE method.
-(EXTSpectralSequence*) upcastToSSeq {
    EXTSpectralSequence *ret = [EXTSpectralSequence new];
    ret.indexClass = self.indexClass;
    ret.multTables.unitTerm = [self findTerm:[self.indexClass identityLocation]];
    
    // for the most part, we're already tracking the structure of a general sseq
    ret.terms = self.terms;
    ret.differentials = self.differentials;
    
    // the zero ranges can mostly be copied over, except for EXTZeroRangeStrict,
    // which is chained to the parent spectral sequence.  so, we make a special
    // except for that class.  ideally this would be 
    ret.zeroRanges = [NSMutableArray arrayWithCapacity:self.zeroRanges.count];
    for (EXTZeroRange *zeroRange in self.zeroRanges) {
        EXTZeroRange *newZeroRange = nil;
        
        if ([[newZeroRange class] isSubclassOfClass:[EXTZeroRangeStrict class]])
            newZeroRange = [EXTZeroRangeStrict newWithSSeq:ret];
        else
            newZeroRange = [zeroRange copy];
        
        [ret.zeroRanges addObject:newZeroRange];
    }
    
    // the real piece that's missing is the multiplicative structure, which we
    // now just iterate straight through and compute.
    for (EXTTerm *leftTerm in ret.terms)
    for (EXTTerm *rightTerm in ret.terms) {
        EXTPartialDefinition *partial = [EXTPartialDefinition new];
        partial.differential = [self productWithLeft:leftTerm.location
                                               right:rightTerm.location];
        partial.inclusion = [EXTMatrix identity:partial.differential.width];
        [self.multTables addPartialDefinition:partial
                                           to:leftTerm.location
                                         with:rightTerm.location];
    }
    
    return ret;
}

-(void) addPolyClass:(NSObject<NSCopying>*)name location:(EXTLocation*)loc upTo:(int)bound {
    // update the navigation members
    NSMutableDictionary *entry = [NSMutableDictionary new];
    
    [entry setObject:name forKey:@"name"];
    [entry setObject:loc forKey:@"location"];
    [entry setObject:@0 forKey:@"upperBound"];
    
    [generators addObject:entry];
    
    [self resizePolyClass:name upTo:bound];
    
    return;
}

-(void) resizePolyClass:(NSObject<NSCopying>*)name upTo:(int)newBound {
    NSMutableDictionary *entry = nil;
    for (NSMutableDictionary *workingEntry in generators)
        if ([[workingEntry objectForKey:@"name"] isEqual:name]) {
            entry = workingEntry;
            break;
        }
    
    // TODO: we can only resize to be larger.  not sure if this is desirable, or
    // if i'll want to come back and allow for shrinking too.
    if ([[entry objectForKey:@"upperBound"] intValue] > newBound)
        return;
    
    // set up the array of counters
    EXTPolynomialTag *tag = [EXTPolynomialTag new];
    tag.tags = [NSMutableDictionary dictionaryWithCapacity:generators.count];
    for (NSMutableDictionary *generator in generators)
        [tag.tags setObject:@0 forKey:[generator objectForKey:@"name"]];
    [tag.tags setObject:@([[entry objectForKey:@"upperBound"] intValue]+1) forKey:name];
    
    BOOL totalRollover = FALSE;
    while (!totalRollover) {
        // search for a term in the location encoded by the counter
        EXTLocation *workingLoc = [[self indexClass] identityLocation];
        for (NSDictionary *generator in generators)
            workingLoc = [[self indexClass] addLocation:workingLoc to:[[self indexClass] scale:[generator objectForKey:@"location"] by:[[tag.tags objectForKey:[generator objectForKey:@"name"]] intValue]]];
        EXTTerm *term = [self findTerm:workingLoc];
        
        // if it doesn't exist, create it
        if (!term) {
            term = [EXTTerm term:workingLoc andNames:[NSMutableArray array]];
            [self.terms setObject:term forKey:workingLoc];
        }
        
        // now add the new tag to its names array
        [term.names addObject:[tag copy]];
        
        // increment the counter
        for (int i = 0;
             i < generators.count ? TRUE : !(totalRollover = TRUE);
             i++) {
            NSDictionary *generator = generators[i];
            int value = [[tag.tags objectForKey:[generator objectForKey:@"name"]] intValue] + 1;
            
            // there are two kinds of roll-over
            if ((generator == entry) && (value > newBound)) {
                [tag.tags setObject:@([[generator objectForKey:@"upperBound"] intValue] + 1) forKey:name];
                continue;
            } else if ((generator != entry) &&
                       (value > [[generator objectForKey:@"upperBound"] intValue])) {
                [tag.tags setObject:@0 forKey:[generator objectForKey:@"name"]];
                continue;
            } else {
                [tag.tags setObject:@(value) forKey:[generator objectForKey:@"name"]];
                break;
            }
        } // for: counter increment
    } // while
    
    // XXX: CHECK ALL DIFFERENTIALS THAT TOUCH THESE CLASSES, AND MODIFY THEIR
    // MATRICES ACCORDINGLY.
    
    // store newBound as the new bound
    [entry setObject:@(newBound) forKey:@"upperBound"];
    
    return;
}

// builds the multiplication matrix for a pair of EXTLocations
-(EXTMatrix*) productWithLeft:(EXTLocation*)leftLoc right:(EXTLocation*)rightLoc {
    EXTTerm *left = [self findTerm:leftLoc], *right = [self findTerm:rightLoc],
    *target = [self findTerm:[[leftLoc class] addLocation:leftLoc to:rightLoc]];
    
    EXTMatrix *ret = [EXTMatrix matrixWidth:(left.size*right.size) height:target.size];
    
    for (int i = 0; i < left.size; i++)
    for (int j = 0; j < right.size; j++) {
        EXTPolynomialTag *sumTag = [EXTPolynomialTag sum:left.names[i] with:right.names[j]];
        int index = [target.names indexOfObject:sumTag];
        if (index != -1) {
            NSMutableArray *retcol = ret.presentation[i*right.size+j];
            retcol[index] = @1;
        }
    }
    
    return ret;
}

-(void) computeLeibniz:(EXTLocation *)loc1
                  with:(EXTLocation *)loc2
                onPage:(int)page {
    EXTLocation *sumLoc = [[loc1 class] addLocation:loc1 to:loc2],
    *targetLoc = [[loc1 class] followDiffl:sumLoc page:page];
    EXTTerm *sumterm = [self findTerm:sumLoc],
    *targetterm = [self findTerm:targetLoc],
    *A = [self findTerm:loc1],
    *B = [self findTerm:loc2];
    EXTDifferential *d1 = [self findDifflWithSource:loc1 onPage:page],
    *d2 = [self findDifflWithSource:loc2 onPage:page];
    
    // if we don't have differentials to work with, then skip this entirely.
    // XXX: i'm not sure this condition is quite right.
    BOOL d1Zero = [self isInZeroRanges:[[loc1 class] followDiffl:loc1 page:page]],
    d2Zero = [self isInZeroRanges:[[loc2 class] followDiffl:loc2 page:page]];
    if ((!d1 && !d1Zero) ||
        (!d2 && !d2Zero) ||
        !targetterm ||
        [self isInZeroRanges:sumLoc] ||
        !sumterm ||
        [self isInZeroRanges:targetLoc])
        return;
    
    // if we're here, then we have all the fixin's we need to construct some
    // more partial differential definitions.  let's find a place to put them.
    EXTDifferential *dsum = [self findDifflWithSource:sumterm.location
                                                    onPage:page];
    if (!dsum) {
        dsum = [EXTDifferential differential:sumterm end:targetterm page:page];
        [self addDifferential:dsum];
    }
    
    // TODO: note that this is duplicated code from EXTMultiplicationTables.
    // there's a reason for this: this is meant to be optimized for the
    // polynomial case.  however, if something breaks there, it will have to
    // also be fixed here.
    if (d1Zero && d2Zero) {
        // in the case that both differentials are zero, no matter what happens
        // we're going to end up with the zero differential off the source.
        EXTPartialDefinition *allZero = [EXTPartialDefinition new];
        allZero.inclusion = [EXTMatrix identity:sumterm.size];
        allZero.differential = [EXTMatrix matrixWidth:sumterm.size
                                               height:targetterm.size];
        [dsum.partialDefinitions addObject:allZero];
    } else if (d1Zero && !d2Zero) {
        for (EXTPartialDefinition *partial2 in d2.partialDefinitions) {
            // in this case, we only have the right-hand differential, so
            // d(xy) = 0 + x dy.  this means building the span
            // A|B <-1|j- A|J -1|partial-> A|Y --mu-> Z.
            EXTMatrix *muAY = [self productWithLeft:loc1 right:[[loc2 class] followDiffl:loc2 page:page]],
                      *muAB = [self productWithLeft:loc1 right:loc2];
            
            EXTPartialDefinition *partial = [EXTPartialDefinition new];
            partial.inclusion =
                [EXTMatrix newMultiply:muAB by:[EXTMatrix hadamardProduct:[EXTMatrix identity:A.size] with:partial2.inclusion]];
            partial.differential = [EXTMatrix newMultiply:muAY by:[EXTMatrix hadamardProduct:[EXTMatrix identity:A.size] with:partial2.differential]];
            
            [dsum.partialDefinitions addObject:partial];
        }
    } else if (!d1Zero && d2Zero) {
        for (EXTPartialDefinition *partial1 in d1.partialDefinitions) {
            // in this case, we only have the left-hand differential, so
            // d(xy) = dx y.  this means building the span
            // A|B <-i|1- I|B -partial|1-> X|B --mu-> Z.
            EXTMatrix *muXB = [self productWithLeft:[[loc1 class] followDiffl:loc1 page:page] right:loc2],
                      *muAB = [self productWithLeft:loc1 right:loc2];
            
            EXTPartialDefinition *partial = [EXTPartialDefinition new];
            partial.inclusion =
                [EXTMatrix newMultiply:muAB by:[EXTMatrix hadamardProduct:partial1.inclusion with:[EXTMatrix identity:B.size]]];
            partial.differential = [EXTMatrix newMultiply:muXB by:[EXTMatrix hadamardProduct:partial1.differential with:[EXTMatrix identity:B.size]]];
            
            [dsum.partialDefinitions addObject:partial];
        }
    } else {
        for (EXTPartialDefinition *partial1 in d1.partialDefinitions)
        for (EXTPartialDefinition *partial2 in d2.partialDefinitions) {
            // in this case, we only both differentials, so d(xy) = dx y + x dy.
            // this means building both spans, then taking their intersection,
            // and summing their action on the intersection.
            EXTMatrix *muAY = [self productWithLeft:loc1 right:[[loc2 class] followDiffl:loc2 page:page]],
                      *muXB = [self productWithLeft:[[loc1 class] followDiffl:loc1 page:page] right:loc2],
                      *muAB = [self productWithLeft:loc1 right:loc2];

            
            EXTMatrix
                *rightInclusion = [EXTMatrix hadamardProduct:[EXTMatrix identity:A.size] with:partial2.inclusion],
                *leftInclusion = [EXTMatrix hadamardProduct:partial1.inclusion with:[EXTMatrix identity:B.size]],
                *rightMultiply = [EXTMatrix newMultiply:muAY by:[EXTMatrix hadamardProduct:[EXTMatrix identity:A.size] with:partial2.differential]],
                *leftMultiply = [EXTMatrix newMultiply:muXB by:[EXTMatrix hadamardProduct:partial1.differential with:[EXTMatrix identity:B.size]]];
            
            NSArray *pair = [EXTMatrix formIntersection:leftInclusion with:rightInclusion];
            
            EXTPartialDefinition *partial = [EXTPartialDefinition new];
            partial.inclusion = [EXTMatrix newMultiply:muAB by:[EXTMatrix newMultiply:leftInclusion by:pair[0]]];
            partial.differential = [EXTMatrix sum:[EXTMatrix newMultiply:leftMultiply by:pair[0]] with:[EXTMatrix newMultiply:rightMultiply by:pair[1]]];
            
            [dsum.partialDefinitions addObject:partial];
        }
    }
    
    if (![dsum checkForSanity])
        NSLog(@"checkForSanity in computeLeibniz failed to pass.");
    
    [dsum stripDuplicates];
    
    return;
}

@end
