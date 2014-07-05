//
//  EXTMaySpectralSequence.m
//  Ext Chart
//
//  Created by Eric Peterson on 7/9/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTMaySpectralSequence.h"
#import "EXTTriple.h"
#import "EXTDifferential.h"

@interface EXTMayTag : NSObject <NSCopying, NSCoding>

@property (assign) int i, j;

+(EXTMayTag*) tagWithI:(int)i J:(int)j;
-(NSString*) description;
-(NSUInteger) hash;

@end

@implementation EXTMayTag

@synthesize i, j;

+(EXTMayTag*) tagWithI:(int)i J:(int)j {
    EXTMayTag *ret = [EXTMayTag new];
    ret.i = i; ret.j = j;
    return ret;
}

-(NSString*) description {
    return [NSString stringWithFormat:@"h_{%d,%d}",i,j];
}

-(EXTMayTag*) copyWithZone:(NSZone*)zone {
    EXTMayTag *ret = [[EXTMayTag allocWithZone:zone] init];
    ret.i = i; ret.j = j;
    return ret;
}

-(BOOL) isEqual:(id)object {
    if ([object class] != [EXTMayTag class])
        return FALSE;
    return ((((EXTMayTag*)object)->i == i) &&
            (((EXTMayTag*)object)->j == j));
}

-(NSUInteger) hash {
    long long key = i;
	key = (~key) + (key << 18); // key = (key << 18) - key - 1;
    key += j;
	key = key ^ (key >> 31);
	key = key * 21; // key = (key + (key << 2)) + (key << 4);
	key = key ^ (key >> 11);
	key = key + (key << 6);
	key = key ^ (key >> 22);
	return (int) key;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        i = [aDecoder decodeIntForKey:@"i"];
        j = [aDecoder decodeIntForKey:@"j"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:i forKey:@"i"];
    [aCoder encodeInteger:j forKey:@"j"];
}

@end




@implementation EXTMaySpectralSequence

-(instancetype) init {
    if (self = [super initWithIndexingClass:[EXTTriple class]]) {
        self.defaultCharacteristic = 2;
    }
    
    return self;
}

// returns a pair {NSArray *vector, EXTTerm *term}
//
// NOTE: i'm concerned that this may ignore important filtration effects. what
// if naive squaring operations tell us what the square 'should' be, but
// this vector is somehow a cycle by the time it matters...? |||| i think maybe
// this isn't something to be worried about.  the squares are already defined on
// the E_1-page, and so there's no helping whether their values later turn out
// to be given by cycles.  on the other hand, maybe this matters for applying
// nakamura's lemma later on.  i have no idea.
-(NSArray*) applySquare:(int)order
               toVector:(NSArray*)vector
             atLocation:(EXTTriple*)location {
    // we know the following three facts about the squaring operations:
    // Sq^n(xy) = sum_{i=0}^n Sq^i x Sq^{n-i} y, (Cartan)
    // Sq^0(h_ij) = h_i(j+1),                    (Nakamura on Sq^0)
    // Sq^1(h_ij) = h_ij^2.                      (Definition of Sq^n on n-class)
    //
    // since we're generated by classes of degree 1, this completely determines
    // the squaring structure everywhere, by iteratively splitting apart a
    // square until we get down to just Sq^0s and Sq^1s.
    //
    // an important thing to realize is that applying this naively yields the
    // differential d2 b30 = h12^2 h21 + h13 h20^2 + h21^2 h11 + h22 h10^2.
    // however, the outer two terms are of lower May filtration than the middle
    // two, and so we project to the higher nonzero May filtration degree to get
    // just d2 b30 = h13 h20^2 + h21^2 h11.  of course, we should *also* only
    // project away to higher filtration classes that actually exist.  for the
    // A(2) May SS, this means that d2 b30 = h12^2 h21, since the other classes
    // have all been deleted by the A --> A(2) quotient.
    
    EXTTerm *startTerm = [self findTerm:location],
            *endTerm = nil;
    NSMutableDictionary *allOutputTerms = [NSMutableDictionary new];
    
    for (int termIndex = 0; termIndex < startTerm.size; termIndex++) {
        // on this pass of the loop, we're going to deal with the term
        // contributed by the [termIndex] component of the vector we were fed
        // in. if our source vector doesn't have a component for this to
        // contribute anything, we should just skip it immediately.
        if (!([vector[termIndex] intValue] & 0x1))
            continue;
        
        // otherwise, pull up all the factors associated to this term.
        EXTPolynomialTag *tag = startTerm.names[termIndex];
        NSArray *tags = tag.tags.allKeys;
        NSMutableArray *counters = [NSMutableArray arrayWithCapacity:tags.count];
        for (int i = 0; i < tags.count; i++)
            counters[i] = @0;
        
        // initialize the counter with the left-most stuffing
        int leftover = order;
        
        // iterate through the available buckets.  this loop breaks out whenever
        // we completely roll over on the carries.
        do {
            // start by initializing the leftmost buckets
            int i;
            for (i = 0; i < tags.count && leftover > 0; i++) {
                int bucketSize = [tag.tags[tags[i]] intValue];
                counters[i] = @(leftover < bucketSize ? leftover : bucketSize);
                leftover -= bucketSize;
            }
            
            // if there are too few factors to apply this high of a square, then
            // just quit.  NOTE that this is NEVER an issue with just one term,
            // because the grading on the May SS is such that the third degree
            // keeps track of EXACTLY how many factors any monomial enjoys.
            if (i == tags.count && leftover > 0)
                return nil;
            
            // at each term, perform the assigned number of Sq^1s, and apply
            // Sq^0 to the remainder.
            // so: (h_ij^n) |-> (n r) h_ij^(2r) h_i(j+1)^(n-r).
            //
            // first, note that 2 | (n r) exactly when r&(n-r) is true. :) so,
            // if that's ever true then we can just skip this summand entirely.
            bool zeroMod2 = false;
            for (int i = 0; i < counters.count; i++) {
                int r = [counters[i] intValue],
                    n = [tag.tags[tags[i]] intValue];
                zeroMod2 |= r & (n - r);
            }
            
            // if we're not 0 mod 2, then we're 1 mod 2.  this means this term
            // has the opportunity to contribute to the broader result, and we
            // update our dictionary allOutputTerms to reflect it.
            if (!zeroMod2) {
                EXTPolynomialTag *targetTag = [EXTPolynomialTag new];
                
                // start by building the tag we're going to be looking up
                for (int i = 0; i < counters.count; i++) {
                    EXTMayTag *hij = tags[i],
                              *hinext = [EXTMayTag tagWithI:hij.i J:(hij.j+1)];
                    int n = [tag.tags[tags[i]] intValue],
                        r = [counters[i] intValue];
                    NSNumber *oldSq0Exp = targetTag.tags[hinext],
                             *oldSq1Exp = targetTag.tags[hij];
                    
                    if (oldSq0Exp)
                        oldSq0Exp = @([oldSq0Exp integerValue] + n-r);
                    else
                        oldSq0Exp = @(n-r);
                    
                    if (oldSq1Exp)
                        oldSq1Exp = @([oldSq1Exp intValue] + 2*r);
                    else
                        oldSq1Exp = @(2*r);
                    
                    targetTag.tags[hinext] = oldSq0Exp;
                    targetTag.tags[hij] = oldSq1Exp;
                }
                
                // if this tag exists in the dictionary, we must discard it,
                // since 1 + 1 = 0 mod 2.
                if (allOutputTerms[targetTag] != nil) {
                    [allOutputTerms removeObjectForKey:targetTag];
                } else {
                    // but if it doesn't exist, then poke a 1 in.
                    allOutputTerms[targetTag] = @1;
                }
            }
            
            // now we move to the next bucket.  start by finding the leftmost
            // nonzero bucket.
            int leftmost = 0;
            for (; leftmost < counters.count && [counters[leftmost] intValue] == 0; leftmost++);
            if (leftmost == counters.count) {
                leftover = order; // force the cartan loop to quit.
                continue;
            }
            
            // this value of this bucket is going to be split into (value-1)+1.
            // the right-hand part of this is used for a carry, and the left-
            // hand part is used for 'leftovers' to minimally reinitialize
            // the leftmost segment of the counters.
            leftover = [counters[leftmost] intValue] - 1;
            counters[leftmost] = @0;
            // continually try to perform carries until we hit a not-maxed bucket
            int carryBuckets = leftmost+1;
            for (; carryBuckets < counters.count; carryBuckets++) {
                if ([counters[carryBuckets] isEqual:[tag.tags objectForKey:tags[carryBuckets]]]) {
                    leftover += [counters[carryBuckets] intValue];
                    counters[carryBuckets] = @0;
                } else {
                    counters[carryBuckets] = @(1 + [counters[carryBuckets] intValue]);
                    break;
                }
            }
            if (carryBuckets == counters.count)
                leftover += 1;
        } while (leftover != order); // cartan loop
    } // term summand loop
    
    // now we need to strip out the highest weight summands from the dictionary
    int activeMayFiltration = -1;
    NSMutableDictionary *strippedOutputTerms = [NSMutableDictionary new];
    for (EXTPolynomialTag *factor in allOutputTerms.allKeys) {
        int a = 0, b = 0, mayFiltration = 0;
        
        // i got this convention from 3.2.3 in the green book. might not be
        // consistent but i don't think that will get in the way. this is a
        // highly localized calculation.
        for (EXTMayTag *subfactor in factor.tags) {
            int power = [factor.tags[subfactor] intValue];
            a += 1*power;
            b += power*((1 << subfactor.j)*((1<<subfactor.i)-1));
            mayFiltration += power*subfactor.i;
        }
        
        if (mayFiltration > activeMayFiltration) {
            // first make sure we're not poking into empty space.
            EXTTerm *term = [self findTerm:[EXTTriple tripleWithA:a B:b C:mayFiltration]];
            if (!term)
                continue;
            
            // then also check that this summand has survived to this location
            if ([term.names indexOfObject:factor] == NSNotFound)
                continue;
            
            strippedOutputTerms = [NSMutableDictionary new];
            activeMayFiltration = mayFiltration;
        }
        
        if (mayFiltration == activeMayFiltration) {
            strippedOutputTerms[factor] = @1;
        }
    }
    
    // if we haven't managed to accrue any summands, then the squaring operation
    // is null, and there's nothing to do about that.
    if (strippedOutputTerms.count == 0)
        return nil;
    
    // otherwise, we do have summands. we should find what term they live in and
    // build a vector out of them.
    endTerm = self.terms[[self computeLocationForTag:strippedOutputTerms.allKeys[0]]];
    
    if (!endTerm)
        return nil;
    
    NSMutableArray *ret = [NSMutableArray new];
    for (int i = 0; i < endTerm.names.count; i++) {
        EXTPolynomialTag *tag = endTerm.names[i];
        NSNumber *value = strippedOutputTerms[tag];
        if (value)
            ret[i] = @1;
        else
            ret[i] = @0;
    }
    
    return @[ret,endTerm];
}

-(EXTTriple*)computeLocationForTag:(EXTPolynomialTag *)tag {
    EXTTriple *ret = [EXTTriple identityLocation];
    
    for (EXTMayTag *factor in tag.tags) {
        EXTTriple *hij = [EXTTriple tripleWithA:1 B:((1 << factor.j)*((1 << factor.i) - 1)) C:factor.i];
        
        ret = [EXTTriple addLocation:ret to:[EXTTriple scale:hij by:[tag.tags[factor] intValue]]];
    }
    
    return ret;
}

// applies the rule Sq^order d_page vector = d Sq^order vector to the vector at
// the location to get a new differential, which it returns.
-(EXTDifferential*) applyNakamura:(int)order
                         toVector:(NSArray*)inVector
                       atLocation:(EXTTriple*)location
                           onPage:(int)page {
    // we need to look up:
    // * the differential on E_new off the target location of Sq^order
    // * the differential on E_old off location
    // * the matrix describing the map Sq^order on E_new
    // * the matrix describing the map Sq^order on E_old
    //
    // then, we apply: d_page (Sq^order x) = Sq^order (d_{page-order} x).
    
    EXTDifferential *underlyingDiff = [self findDifflWithSource:location onPage:page];
    if (!underlyingDiff)
        return nil;
    
    EXTTriple *startLocation = (EXTTriple*)underlyingDiff.start.location,
              *endLocation = (EXTTriple*)underlyingDiff.end.location;
    
    // check that this vector actually lies in the well-defined part of the
    // partial differentials!  (+) all the inclusion matrices together and take
    // a pullback to see if it's nonzero.
    EXTMatrix *bigInclusion = [EXTMatrix matrixWidth:0 height:underlyingDiff.start.names.count];
    bigInclusion.characteristic = 2;
    for (EXTPartialDefinition *partial in underlyingDiff.partialDefinitions) {
        bigInclusion.width = bigInclusion.width + partial.inclusion.width;
        [bigInclusion.presentation addObjectsFromArray:partial.inclusion.presentation];
    }
    EXTMatrix *smallInclusion = [EXTMatrix matrixWidth:1 height:underlyingDiff.start.names.count];
    smallInclusion.characteristic = 2;
    smallInclusion.presentation[0] = inVector;
    EXTMatrix *pullback = (EXTMatrix*)[EXTMatrix formIntersection:bigInclusion with:smallInclusion][1];
    [pullback modularReduction];
    
    bool inVectorIsCovered = false;
    for (int i = 0; i < pullback.width; i++) {
        if ([pullback.presentation[i][0] intValue] != 0)
            inVectorIsCovered = true;
    }
    if (!inVectorIsCovered)
        return nil;
    
    // if we've made it this far, then we're really contributing some defn.
    // try to compute nakamura's rule.
    NSMutableArray *cycles = underlyingDiff.start.cycles[underlyingDiff.page];
    EXTMatrix *cycleInclusion =
        [EXTMatrix matrixWidth:cycles.count height:underlyingDiff.start.size];
    cycleInclusion.presentation = cycles;
    cycleInclusion.characteristic = 2;
    EXTMatrix *vectorInCycleCoords = [EXTMatrix formIntersection:smallInclusion with:cycleInclusion][1];
    [underlyingDiff assemblePresentation];
    
    NSArray *outVector = [EXTMatrix newMultiply:underlyingDiff.presentation by:vectorInCycleCoords].presentation[0];
    
    NSArray *startSquarePair = [self applySquare:order
                                        toVector:inVector
                                      atLocation:startLocation],
            *endSquarePair = [self applySquare:order
                                      toVector:outVector
                                    atLocation:endLocation];
    
    // if either squaring calculation failed, bail.
    if (!startSquarePair || !endSquarePair)
        return nil;
    
    NSArray *startSquare = startSquarePair[0], *endSquare = endSquarePair[0];
    EXTTerm *newStart = startSquarePair[1], *newEnd = endSquarePair[1];
    
    int newPage = [EXTTriple calculateDifflPage:newStart.location end:newEnd.location];
    if (newPage == -1) {
        NSLog(@"Something has gone horribly wrong in calculateNakamura...");
        return nil;
    }
    
    EXTDifferential *diff = [self findDifflWithSource:newStart.location onPage:newPage];
    if (!diff) {
        diff = [EXTDifferential differential:newStart end:newEnd page:newPage];
        [self addDifferential:diff];
    }
    
    // add a new partial definition to diff specified by our rule:
    //                     d Sq^order v = Sq^order d v.
    EXTPartialDefinition *partial = [EXTPartialDefinition new];
    partial.inclusion = [EXTMatrix matrixWidth:1 height:startSquare.count];
    partial.inclusion.presentation[0] = startSquare;
    partial.inclusion.characteristic = 2;
    partial.action = [EXTMatrix matrixWidth:1 height:endSquare.count];
    partial.action.presentation[0] = endSquare;
    partial.action.characteristic = 2;
    partial.description = [NSString stringWithFormat:@"Nakamura's lemma applied along Sq^%d on E_%d^%@", order, page, location];
    [diff.partialDefinitions addObject:partial];

    return diff;
}

+(EXTMaySpectralSequence*) fillForAn:(NSInteger)n width:(int)width {
    EXTMaySpectralSequence *sseq = [EXTMaySpectralSequence new];
    
    [sseq.zeroRanges addObject:[EXTZeroRangeStrict newWithSSeq:sseq]];
    EXTZeroRangeTriple *zrTriple = [EXTZeroRangeTriple new];
    zrTriple.leftEdge = zrTriple.bottomEdge = zrTriple.backEdge = 0;
    zrTriple.rightEdge = zrTriple.topEdge = zrTriple.frontEdge = width;
    [sseq.zeroRanges addObject:zrTriple];
    
    bool (^ condition)(EXTTriple*) = ^(EXTTriple *loc){
        return (bool) (loc.b <= width);
    };
    
    // start by adding the polynomial terms h_{i,j}
    for (int i = 1; ; i++) {
        
        // if we've passed outside of the width or left A(n), then quit.
        if (((1 << i)-2 > width) || (i > n+1))
            break;
        
        for (int j = 0; ; j++) {
            // calculate the location of the present term
            int A = 1, B = (1 << j)*((1 << i) - 1), C = i;
            
            // if we're outside the width limit *or* if we've hit the truncation
            // level, then it's time to move on to the next element.
            if ((B - 1 > width) || (j > (n-i+1)))
                break;
            
            int limit = ((i == 1) && (j == 0)) ? width : width/(B-1);
            
            [sseq addPolyClass:[EXTMayTag tagWithI:i J:j]
                      location:[EXTTriple tripleWithA:A B:B C:C]
                          upTo:limit
                   onCondition:(bool (^)(EXTLocation*))condition];
        }
    }
    
    [sseq buildDifferentials];
    
    return sseq;
}

+(EXTMaySpectralSequence*) fillToWidth:(int)width {
    return [EXTMaySpectralSequence fillForAn:width width:width];
}

-(void) buildDifferentials {
    // add the d1 differentials
    for (NSDictionary *generator in self.generators) {
        EXTMayTag *tag = [generator objectForKey:@"name"];
        int i = tag.i, j = tag.j;
        
        // these elements are genuinely primitive, so never support diff'ls.
        if (i == 1)
            continue;
        
        EXTTriple *location = [generator objectForKey:@"location"];
        EXTTerm *target = [self findTerm:[EXTTriple followDiffl:location page:1]];
        EXTDifferential *diff = [EXTDifferential differential:[self findTerm:location] end:target page:1];
        EXTPartialDefinition *partial = [EXTPartialDefinition new];
        partial.inclusion = [EXTMatrix identity:1];
        partial.action = [EXTMatrix matrixWidth:1 height:target.size];
        partial.inclusion.characteristic = 2;
        partial.action.characteristic = 2;
        
        // the formula for the May d_1 comes straight from the Steenrod
        // diagonal: d_1 h_{i,j} = sum_{k=1}^{i-1} h_{k,i-k+j} h_{i-k,j}
        for (int k = 1; k <= i-1; k++) {
            EXTMayTag *tagLeft = [EXTMayTag tagWithI:k J:(i-k+j)],
            *tagRight = [EXTMayTag tagWithI:(i-k) J:j];
            
            NSDictionary *leftEntry = nil, *rightEntry = nil;
            for (NSDictionary *workingEntry in self.generators)
                if ([[workingEntry objectForKey:@"name"] isEqual:tagLeft])
                    leftEntry = workingEntry;
                else if ([[workingEntry objectForKey:@"name"] isEqual:tagRight])
                    rightEntry = workingEntry;
            EXTMatrix *product =
                [self productWithLeft:[leftEntry objectForKey:@"location"]
                                right:[rightEntry objectForKey:@"location"]];
            
            // don't bother if we don't know about this term.
            if (!product || product.width == 0 || product.height == 0)
                continue;
            
            partial.action = [EXTMatrix sum:partial.action with:product];
        }
        
        partial.description = [NSString stringWithFormat:@"May d1 differential on %@",tag];
        [diff.partialDefinitions addObject:partial];
        [self addDifferential:diff];
    }
    
    // propagate the d1 differentials with Leibniz's rule
    NSMutableArray *locations = [NSMutableArray array];
    for (NSMutableDictionary *generator in self.generators)
        [locations addObject:[generator objectForKey:@"location"]];
    [self propagateLeibniz:locations page:1];
    
    return;
}

@end
