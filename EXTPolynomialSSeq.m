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

@end



//
// now, the actual polynomial spectral sequence class.
//
@implementation EXTPolynomialSSeq

@synthesize names, locations, upperBounds;

-(EXTMultiplicationTables*) multTables {
    NSLog(@"EXTPolynomialSSeq %@ was asked for its multTables.", self);
    return nil;
}

// blank out the new member variables
-(EXTPolynomialSSeq*) init {
    self = [super init];
    
    names = [NSMutableArray array];
    locations = [NSMutableArray array];
    upperBounds = [NSMutableArray array];
    
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
-(EXTSpectralSequence*) upcastToSSeq {
    NSLog(@"upcastToSSeq not yet implemented.");
    return nil;
}

-(void) addPolyClass:(NSObject*)name location:(EXTLocation*)loc upTo:(int)bound {
    // update the navigation members
    [names addObject:name];
    [locations addObject:loc];
    [upperBounds addObject:@0];
    
    [self resizePolyClass:name upTo:bound];
    
    return;
}

-(void) resizePolyClass:(NSObject*)name upTo:(int)newBound {
    int index = [names indexOfObject:name];
    
    // TODO: we can only resize to be larger.  not sure if this is desirable, or
    // if i'll want to come back and allow for shrinking too.
    if ([upperBounds[index] intValue] > newBound)
        return;
    
    // set up the array of counters
    EXTPolynomialTag *tag = [EXTPolynomialTag new];
    tag.tags = [NSMutableDictionary dictionaryWithCapacity:names.count];
    for (int i = 0; i < names.count; i++)
        [tag.tags setObject:@0 forKey:names[i]];
    [tag.tags setObject:@([upperBounds[index] intValue]+1) forKey:names[index]];
    
    BOOL totalRollover = FALSE;
    while (!totalRollover) {
        // search for a term in the location encoded by the counter
        EXTLocation *workingLoc = [[self indexClass] identityLocation];
        for (int i = 0; i < names.count; i++)
            workingLoc = [[self indexClass] addLocation:workingLoc to:[[self indexClass] scale:locations[i] by:[[tag.tags objectForKey:names[i]] intValue]]];
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
             i < names.count ? TRUE : !(totalRollover = TRUE);
             i++) {
            int value = [[tag.tags objectForKey:names[i]] intValue] + 1;
            
            // there are two kinds of roll-over
            if ((i == index) && (value > newBound)) {
                [tag.tags setObject:@([upperBounds[index] intValue] + 1) forKey:names[index]];
                continue;
            } else if ((i != index) && (value > [upperBounds[i] intValue])) {
                [tag.tags setObject:@0 forKey:names[i]];
                continue;
            } else {
                [tag.tags setObject:@(value) forKey:names[i]];
                break;
            }
        } // for: counter increment
    } // while
    
    // XXX: CHECK ALL DIFFERENTIALS THAT TOUCH THESE CLASSES, AND MODIFY THEIR
    // MATRICES ACCORDINGLY.
    
    // store newBound as the new bound
    upperBounds[index] = @(newBound);
    
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
