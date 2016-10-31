//
//  EXTSpectralSequence.m
//  Ext Chart
//
//  Created by Eric Peterson on 5/31/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTSpectralSequence.h"
#import "EXTPair.h"
#import "EXTTriple.h"
#import "EXTTerm.h"
#import "EXTDifferential.h"
#import "EXTMultiplicationTables.h"
#import "EXTMatrix.h"

@implementation EXTSpectralSequence

@synthesize terms, differentials, multTables, indexClass, zeroRanges,
            locConvertor, defaultCharacteristic;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        terms = [aDecoder decodeObjectForKey:@"terms"];
        defaultCharacteristic =
                        [aDecoder decodeIntegerForKey:@"defaultCharacteristic"];
        
        differentials = [aDecoder decodeObjectForKey:@"differentials"];
        for (NSDictionary *page in differentials)
        for (EXTDifferential *diff in page.allValues) {
            diff.start = [terms objectForKey:((EXTLocation*)diff.start)];
            diff.end = [terms objectForKey:((EXTLocation*)diff.end)];
        }
        
        multTables = [aDecoder decodeObjectForKey:@"multTables"];
        multTables.sSeq = self;
        multTables.unitTerm = [terms objectForKey:((EXTLocation*)multTables.unitTerm)];
        
        switch ([aDecoder decodeIntForKey:@"indexClass"]) {
            case EXTPair_KIND:
                indexClass = [EXTPair class];
                break;
            case EXTTriple_KIND:
                indexClass = [EXTTriple class];
                break;
            default:
                NSLog(@"unrecognized indexClass kind on load");
                indexClass = [EXTPair class];
                break;
        }
        
        locConvertor = [aDecoder decodeObjectForKey:@"locConvertor"];
        
        zeroRanges = [aDecoder decodeObjectForKey:@"zeroRanges"];
        for (EXTZeroRange *zeroRange in zeroRanges) {
            if ([zeroRange isKindOfClass:[EXTZeroRangeStrict class]])
                [(EXTZeroRangeStrict*)zeroRange setSSeq:self];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:terms forKey:@"terms"];
    [aCoder encodeInt:defaultCharacteristic forKey:@"defaultCharacteristic"];
    [aCoder encodeObject:differentials forKey:@"differentials"];
    [aCoder encodeObject:multTables forKey:@"multTables"];
    [aCoder encodeObject:zeroRanges forKey:@"zeroRanges"];
    
    if ([[EXTPair class] isEqual:indexClass]) {
        [aCoder encodeInteger:EXTPair_KIND forKey:@"indexClass"];
    } else if ([[EXTTriple class] isEqual:indexClass]) {
        [aCoder encodeInteger:EXTTriple_KIND forKey:@"indexClass"];
    } else {
        NSLog(@"unrecognized indexClass on write");
        [aCoder encodeInteger:EXTPair_KIND forKey:@"indexClass"];
    }
    
    [aCoder encodeObject:locConvertor forKey:@"locConvertor"];
}

-(EXTSpectralSequence*) initWithIndexingClass:(Class<EXTLocation>)locClass
                            andCharacteristic:(int)characteristic {
    if (self = [super init]) {
        defaultCharacteristic = characteristic;
        terms = [NSMutableDictionary dictionary];
        differentials = [NSMutableArray array];
        differentials[0] = [NSMutableDictionary dictionary];
        multTables = [EXTMultiplicationTables multiplicationTables:self];
        zeroRanges = [NSMutableArray array];
        [zeroRanges addObject:[EXTZeroRangeStrict newWithSSeq:self]];
        indexClass = locClass;
        
        if ([[EXTPair class] isEqual:locClass]) {
            self.locConvertor = [EXTPairToPoint new];
        } else if ([[EXTTriple class] isEqual:locClass]) {
            self.locConvertor = [EXTTripleToPoint new];
        } else {
            DLog(@"-initWithIndexingClass doesn't recognize EXTLocationToPoint.");
        }
    }
    
    return self;
}

-(EXTSpectralSequence*) init {
    self = [super init];
    
    // and allocate the internal parts of things
    defaultCharacteristic = 0;
    terms = [NSMutableDictionary dictionary];
    differentials = [NSMutableArray array];
    differentials[0] = [NSMutableDictionary dictionary];
    multTables = [EXTMultiplicationTables multiplicationTables:self];
    indexClass = [EXTPair class];
    locConvertor = [EXTPairToPoint new];
    zeroRanges = [NSMutableArray array];
    [zeroRanges addObject:[EXTZeroRangeStrict newWithSSeq:self]];
    
    return self;
}

+(EXTSpectralSequence*) sSeqWithIndexingClass:(Class<EXTLocation>)locClass
                            andCharacteristic:(int)characteristic {
    return [[EXTSpectralSequence alloc] initWithIndexingClass:locClass
                                            andCharacteristic:characteristic];
}

+(EXTSpectralSequence*) sSeqWithUnit:(Class<EXTLocation>)locClass
                   andCharacteristic:(int)characteristic {
    return [EXTSpectralSequence buildLaurentSSeq:@"1" location:[locClass identityLocation] upTo:0 downTo:0 andCharacteristic:0];
}


// returns an EXTSpectralSequence which is given by the tensor product of the
// current spectral sequence with an incoming collection of classes with
// multiplication and diff'ls.
//
// apologies about my style; you can very much tell that i'm used to working in
// a language with strong typing and an easy production of tuple types, neither
// of which is quite true in Objective-C.  i'm not about to make a zillion
// helper classes, though.
//
// XXX: each of these pieces should deal with the respective zero ranges in some
// way. this means both computing the zero range of the tensor and handling
// the existing ranges well when computing e.g. the leibniz rule.
-(EXTSpectralSequence*) tensorWithSSeq:(EXTSpectralSequence *)p {
    // what we'll eventually be returning.
    EXTSpectralSequence *ret = NULL;
    
    {
        int a = self.defaultCharacteristic,
            b = p.defaultCharacteristic,
            gcd = 0;
        
        EXTComputeGCD(&a, &b, &gcd, NULL, NULL);
        
        ret = [EXTSpectralSequence sSeqWithIndexingClass:self.indexClass
                                       andCharacteristic:gcd];
    }

    NSMutableArray *tensorTerms = [NSMutableArray array];
    
    // we need to do a bunch of manipulations over pairs of classes.
    for (EXTTerm *t1 in self.terms.allValues) {
        for (EXTTerm *t2 in p.terms.allValues) {
            // build EXTTerm's for all the tensor pairs A (x) P, and store
            // these in a separate list.
            EXTLocation *loc = [[t1.location class] addLocation:t1.location
                                                             to:t2.location];
            NSMutableArray *names = [NSMutableArray array];
            for (int i = 0; i < t1.size; i++)
                for (int j = 0; j < t2.size; j++)
                    [names addObject:[NSString stringWithFormat:@"%@ %@", t1.names[i], t2.names[j]]];
            
            EXTTerm *t1t2 = [EXTTerm term:loc withNames:names andCharacteristic:defaultCharacteristic];
            t1t2.cycles[0] = [EXTMatrix hadamardProduct:t1.cycles[0] with:t2.cycles[0]];
            t1t2.boundaries[0] = [EXTMatrix hadamardProduct:t1.boundaries[0] with:t2.boundaries[0]];
            
            [tensorTerms addObject:
                [NSMutableArray arrayWithArray:@[t1t2, t1, t2, @false]]];
        }
    }
    
    // some of these new EXTTerms will have overlapping EXTLocations. the next
    // thing to do is to collect them together into one large EXTTerm per
    // EXTLocation, remembering which term was added in which order.
    NSMutableArray *splicedTensorTerms = [NSMutableArray array];
    for (NSMutableArray *term in tensorTerms) {
        // if this term has already been accounted for, then we must skip it.
        if ([term[3] isEqual:@true])
            continue;
        
        // otherwise, this designates some fresh EXTLocation.
        EXTLocation *loc = [(EXTTerm*)term[0] location];
        // iterate through all the terms, finding all the ones which share loc
        NSMutableArray *atThisLoc = [NSMutableArray array];
        for (NSMutableArray *workingTerm in tensorTerms) {
            if ([[(EXTTerm*)workingTerm[0] location] isEqual:loc]) {
                [atThisLoc addObject:workingTerm];
                workingTerm[3] = @true;
            }
        }
        
        // now, we sum them together. we want a list of names.
        NSMutableArray *sumNames = [NSMutableArray array];
        EXTMatrix *sumCycles = [EXTMatrix matrixWidth:0 height:0],
              *sumBoundaries = [EXTMatrix matrixWidth:0 height:0];
        for (NSMutableArray *workingTerm in atThisLoc) {
            [sumNames addObjectsFromArray:((EXTTerm*)workingTerm[0]).names];
            sumCycles = [EXTMatrix directSum:sumCycles with:((EXTTerm*)workingTerm[0]).cycles[0]];
            sumBoundaries = [EXTMatrix directSum:sumBoundaries with:((EXTTerm*)workingTerm[0]).boundaries[0]];
        }
        
        EXTTerm *splicedTerm = [EXTTerm term:loc withNames:sumNames andCharacteristic:defaultCharacteristic];
        splicedTerm.cycles[0] = sumCycles;
        splicedTerm.boundaries[0] = sumBoundaries;
        
        // finally, add the summed term and its child terms to the spliced terms
        [splicedTensorTerms addObject:@[splicedTerm, atThisLoc]];
    }
    
    // store these terms into the returning spectral sequence.
    for (NSMutableArray* tuple in splicedTensorTerms) {
        [ret.terms setObject:tuple[0] forKey:((EXTTerm*)tuple[0]).location];
    }
    
    // XXX: i don't think that this is **summing** differentials correctly...
    NSMutableArray *outputDifferentials = [NSMutableArray array];
    // iterate over pairs of existing terms to build differentials from old ones
    for (NSMutableArray *tuple in splicedTensorTerms) {
        EXTTerm *start = tuple[0];
        NSMutableArray *startSummands = tuple[1];
        
        // find all the differentials involving any of the working left-summands
        NSMutableArray *partialPresentations = [NSMutableArray array];
        for (NSMutableDictionary *dictionary in self.differentials)
        for (EXTDifferential *d1 in dictionary.allValues) {
            // check if this diff'l is attached to one of our left-summands.
            int sourceIndex = -1, sourceOffset = 0;
            for (int i = 0; i < startSummands.count; i++) {
                NSMutableArray *tuple = startSummands[i];
                if (tuple[1] == d1.start) {
                    sourceIndex = i;
                    break;
                }
                sourceOffset += ((EXTTerm*)tuple[1]).size;
            }
            if (sourceIndex == -1)
                continue;
            
            EXTTerm *AP = ((NSMutableArray*)startSummands[sourceIndex])[0],
                     *P = ((NSMutableArray*)startSummands[sourceIndex])[2];
            
            // ok, so this differential is attached to our source term. we now
            // find all the same data for its target term.
            int endIndex = -1, endOffset = 0;
            NSMutableArray *endSummands = nil;
            EXTTerm *end = nil;
            for (NSMutableArray *workingTuple in splicedTensorTerms) {
                end = workingTuple[0];
                endSummands = workingTuple[1];
                endIndex = -1, endOffset = 0;
                for (int i = 0; i < endSummands.count; i++) {
                    NSMutableArray *tuple = endSummands[i];
                    if ((tuple[1] == d1.end) && (tuple[2] == P)) {
                        endIndex = i;
                        break;
                    }
                    endOffset += ((EXTTerm*)tuple[0]).size;
                }
                
                if (endIndex != -1)
                    break;
            }
            
            EXTTerm *BP = ((NSMutableArray*)endSummands[endIndex])[0];
            
            // an EXTPartialDefinition used to look like A <-i--< A' --d-> B.
            // now we're going to tensor up to P, which will give something like
            // (+)_I A|P <-i1- A|P <-(i|1)-< A'|P -(d|1)-> B|P -i2-> (+)_J B|P.
            // many of these pieces are common to varying i and d, so we pre-
            // compute the ones we can hold constant.
            EXTMatrix *idP = [EXTMatrix identity:P.size];
            EXTMatrix *i1 = [EXTMatrix includeEvenlySpacedBasis:AP.size endDim:start.size offset:sourceOffset spacing:1];
            EXTMatrix *i2 = [EXTMatrix includeEvenlySpacedBasis:BP.size endDim:end.size offset:endOffset spacing:1];
            
            // now we iterate through the available i and d.
            NSMutableArray *partialsForThisD = [NSMutableArray array];
            for (EXTPartialDefinition *partial in d1.partialDefinitions) {
                EXTPartialDefinition *newPartial = [EXTPartialDefinition new];
                EXTMatrix *ix1 = [EXTMatrix hadamardProduct:partial.inclusion with:idP];
                EXTMatrix *dx1 = [EXTMatrix hadamardProduct:partial.action with:idP];
                ix1.characteristic = ret.defaultCharacteristic;
                dx1.characteristic = ret.defaultCharacteristic;
                newPartial.inclusion = [EXTMatrix newMultiply:i1 by:ix1];
                newPartial.action = [EXTMatrix newMultiply:i2 by:dx1];
                partial.description = [NSString stringWithFormat:@"Tensored up from %@ (x) %@",d1.start.location,P.location];
                [partialsForThisD addObject:partial];
            }
            
            [partialPresentations addObject:[NSMutableArray arrayWithObjects:start, end, @(d1.page), partialsForThisD, @false, nil]];
        } // d1
        
        // now also do d2.
        // XXX: THIS IS DUPLICATED CODE. BUGS IN ONE MEAN BUGS IN THE OTHER.
        // CORRECT APPROPRIATELY, AND EVENTUALLY FACTOR THIS ALL OUT.
        for (NSMutableDictionary *dictionary in p.differentials)
        for (EXTDifferential *d2 in dictionary.allValues) {
            // check if this diff'l is attached to one of our right-summands.
            int sourceIndex = -1, sourceOffset = 0;
            for (int i = 0; i < startSummands.count; i++) {
                NSMutableArray *tuple = startSummands[i];
                if (tuple[2] == d2.start) {
                    sourceIndex = i;
                    break;
                }
                sourceOffset += ((EXTTerm*)tuple[2]).size;
            }
            if (sourceIndex == -1)
                continue;
            
            EXTTerm *AP = ((NSMutableArray*)startSummands[sourceIndex])[0],
                    *A = ((NSMutableArray*)startSummands[sourceIndex])[1];
            
            // ok, so this differential is attached to our source term. we now
            // find all the same data for its target term.
            int endIndex = -1, endOffset = 0;
            NSMutableArray *endSummands = nil;
            EXTTerm *end = nil;
            for (NSMutableArray *workingTuple in splicedTensorTerms) {
                end = workingTuple[0];
                endSummands = workingTuple[1];
                endIndex = -1, endOffset = 0;
                for (int i = 0; i < endSummands.count; i++) {
                    NSMutableArray *tuple = endSummands[i];
                    if ((tuple[1] == A) && (tuple[2] == d2.end)) {
                        endIndex = i;
                        break;
                    }
                    endOffset += ((EXTTerm*)tuple[0]).size;
                }
                
                if (endIndex != -1)
                    break;
            }
            
            EXTTerm *AQ = ((NSMutableArray*)endSummands[endIndex])[0];
            
            // an EXTPartialDefinition used to look like P <-i--< P' --d-> Q.
            // now we're going to tensor up to A, which will give something like
            // (+)_I A|P <-i1- A|P <-(1|i)-< A|P' -(1|d)-> A|Q -i2-> (+)_J A|Q.
            // many of these pieces are common to varying i and d, so we pre-
            // compute the ones we can hold constant.
            EXTMatrix *idA = [EXTMatrix identity:A.size];
            EXTMatrix *i1 = [EXTMatrix includeEvenlySpacedBasis:AP.size endDim:start.size offset:sourceOffset spacing:1];
            EXTMatrix *i2 = [EXTMatrix includeEvenlySpacedBasis:AQ.size endDim:end.size offset:endOffset spacing:1];
            
            // now we iterate through the available i and d.
            NSMutableArray *partialsForThisD = [NSMutableArray array];
            for (EXTPartialDefinition *partial in d2.partialDefinitions) {
                EXTPartialDefinition *newPartial = [EXTPartialDefinition new];
                EXTMatrix *ix1 = [EXTMatrix hadamardProduct:idA with:partial.inclusion];
                EXTMatrix *dx1 = [EXTMatrix hadamardProduct:idA with:partial.action];
                ix1.characteristic = ret.defaultCharacteristic;
                dx1.characteristic = ret.defaultCharacteristic;
                newPartial.inclusion = [EXTMatrix newMultiply:i1 by:ix1];
                newPartial.action = [EXTMatrix newMultiply:i2 by:dx1];
                partial.description = [NSString stringWithFormat:@"Tensored up from %@ (x) %@",A.location,d2.start.location];
                [partialsForThisD addObject:partial];
            }
            
            [partialPresentations addObject:[NSMutableArray arrayWithObjects:start, end, @(d2.page), partialsForThisD, @false, nil]];
        } // d2
        
        // now collect all the differentials that live on the same term.
        for (NSMutableArray *tagPartial in partialPresentations) {
            if ([tagPartial[4] boolValue]) // if we've already collected this...
                continue;                  // ... skip it.
            
            // otherwise, this is a new page, so a new differential.
            EXTDifferential *diff = [EXTDifferential differential:tagPartial[0] end:tagPartial[1] page:[tagPartial[2] intValue]];
            for (NSMutableArray *workingPartial in partialPresentations) {
                if ((workingPartial[0] != tagPartial[0]) ||
                    (workingPartial[1] != tagPartial[1]))
                    continue;
                [diff.partialDefinitions addObjectsFromArray:tagPartial[3]];
                tagPartial[4] = @true;
            }
            
            while (diff.page <= outputDifferentials.count)
                outputDifferentials[outputDifferentials.count] = [NSMutableDictionary dictionary];
            [outputDifferentials[diff.page] setObject:diff forKey:diff.start.location];
        } // partialPresentations
    } // splicedTensorTerms
    
    // store these differentials in to the returning spectral sequence
    ret.differentials = outputDifferentials;
    
    // initialize the multiplication tables for the returning spectral sequence
    ret.multTables = [EXTMultiplicationTables multiplicationTables:ret];
    
    // iterate over pairs of splicedTensorTerms
    for (NSMutableArray *leftPair in splicedTensorTerms)
    for (NSMutableArray *rightPair in splicedTensorTerms) {
        EXTTerm *leftTerm = leftPair[0],
                *rightTerm = rightPair[0];
        NSMutableArray *leftSummands = leftPair[1],
                      *rightSummands = rightPair[1];
        
        // iterate over pairs of old terms which belong to splicedVectorTerms
        for (NSMutableArray *leftSummand in leftSummands)
        for (NSMutableArray *rightSummand in rightSummands) {
            EXTTerm *A = leftSummand[1], *P = leftSummand[2],
                    *B = rightSummand[1], *Q = rightSummand[2];
            
            EXTMultiplicationEntry
                *leftEntry = [self.multTables performSoftLookup:A.location
                                                           with:B.location],
                *rightEntry = [p.multTables performSoftLookup:P.location
                                                         with:Q.location];
            if (!leftEntry || !rightEntry)
                continue;
            
            NSMutableArray
                *leftPartials = leftEntry.partialDefinitions,
                *rightPartials = rightEntry.partialDefinitions;
            
            // look up the target term, which we need for indexing purposes.
            EXTTerm *C = [self findTerm:[[A.location class] addLocation:A.location to:B.location]],
                    *R = [p findTerm:[[P.location class] addLocation:P.location to:Q.location]];
            
            // if we're not going to multiply into anything, then the
            // multiplication is zero/undefined and we skip it.
            if (!C || !R)
                continue;
            
            EXTTerm *CR = nil, *CRplus = nil;
            int CRoffset = 0;
            for (NSMutableArray *workingTuple in splicedTensorTerms) {
                for (NSMutableArray *subTuple in workingTuple[1]) {
                    if ((subTuple[1] == C) &&
                        (subTuple[2] == R)) {
                        CR = subTuple[0];
                        CRplus = workingTuple[0];
                        break;
                    } else CRoffset += ((EXTTerm*)(subTuple[0])).size;
                }
                if (CR) break;
                CRoffset = 0;
            }
            
            int BQoffset = 0;
            for (int i = 0; i < [rightSummands indexOfObject:rightSummand]; i++)
                BQoffset += ((EXTTerm*)(rightSummands[i])).size;
            
            // while we're at it, build the inclusion matrix C|R --> (+) C|R
            EXTMatrix *i2 = [EXTMatrix includeEvenlySpacedBasis:CR.size endDim:CRplus.size offset:CRoffset spacing:1];
            
            for (EXTPartialDefinition *leftPartial in leftPartials)
            for (EXTPartialDefinition *rightPartial in rightPartials) {
                EXTPartialDefinition *tensorPartial = [EXTPartialDefinition new];
                
                // A|B <-i- I -f-> C and P|Q <-j- J -g-> R become the pair
                // I|J -i|j-> (A|B)|(P|Q) -i1-> ((+)A|P)|((+)B|Q) ,
                // I|J -f|g-> C|R -i2-> (+) C|R .
                // this second one is easy, so we do it first.
                tensorPartial.inclusion = [EXTMatrix newMultiply:i2 by:[EXTMatrix hadamardProduct:leftPartial.inclusion with:rightPartial.inclusion]];
                
                // this biggest challenge is constructing i1.  this matrix has
                // to include across the reassociation and transposition
                // (A|B)|(P|Q) ~= (A|P)|(B|Q), along with dealing with one of
                // the big direct sum inclusions we're constructing.
                EXTMatrix *i1 = [EXTMatrix matrixWidth:(A.size*B.size*P.size*Q.size) height:(leftTerm.size*rightTerm.size)];
                
                for (int i = 0; i < A.size; i++)
                for (int j = 0; j < P.size; j++)
                for (int k = 0; k < B.size; k++)
                for (int l = 0; l < Q.size; l++) {
                    int APskip = B.size*Q.size*([leftSummands indexOfObject:leftSummand] + i*P.size + j);
                    // poke a 1 in at this location.  the only way to see that
                    // this is a reasonable thing to do is to draw out an
                    // example.  i'm very sorry. :(
                    //
                    // addendum: because this is where we deal with commuting
                    // P across B, this is also where the koszul sign rule shows
                    // up. that's what that little conditional is about.
                    ((int*)i1.presentation.mutableBytes)[(l+Q.size*(j+P.size*(k+i*B.size)))*i1.height + (APskip + BQoffset + k*Q.size + l)] = (B.location.koszulDegree * P.location.koszulDegree) & 0x1 ? -1 : 1;
                }
                
                // now, we use this to build the differential presentation.
                tensorPartial.action = [EXTMatrix newMultiply:i1 by:[EXTMatrix hadamardProduct:leftPartial.action with:rightPartial.action]];
                
                // store to the table
                [ret.multTables addPartialDefinition:tensorPartial
                                                  to:[leftTerm location]
                                                with:[rightTerm location]];
            } // left/rightPartials
        } // left/rightSummands
    } // splicedTensorTerms
    
    return ret;
}

-(EXTSpectralSequence*) tensorWithPolyClass:(NSString*)name
                                  location:(EXTLocation*)loc
                                      upTo:(int)upTo {
    return [self tensorWithLaurentClass:name location:loc upTo:upTo downTo:0];
}

-(EXTSpectralSequence*) tensorWithLaurentClass:(NSString*)name
                                     location:(EXTLocation*)loc
                                         upTo:(int)upTo
                                       downTo:(int)downTo {
    return [self tensorWithSSeq:[EXTSpectralSequence buildLaurentSSeq:name location:loc upTo:upTo downTo:downTo andCharacteristic:0]];
}

+(EXTSpectralSequence*) buildLaurentSSeq:(NSString*)name
                                location:(EXTLocation*)loc
                                    upTo:(int)upTo
                                  downTo:(int)downTo
                       andCharacteristic:(int)characteristic {
    Class<EXTLocation> locClass = [loc class];
    EXTSpectralSequence *l =
        [EXTSpectralSequence sSeqWithIndexingClass:locClass
                                 andCharacteristic:characteristic];
    
    // construct a bunch of terms
    for (int i = downTo; i <= upTo; i++) {
        // TODO: possibly there's a better way to name these classes. at the
        // moment, i've opted to name them for easy LaTeX printing.
        EXTLocation *workingLoc = [locClass scale:loc by:i];
        EXTTerm *workingTerm = [EXTTerm term:workingLoc withNames:
                                [NSMutableArray arrayWithObject:
                                 [NSString stringWithFormat:@"(%@)^{%d}",
                                  name, i]]
                                andCharacteristic:0];
        [l.terms setObject:workingTerm forKey:workingLoc];
    }
    
    // now we throw in the internal multiplicative structure
    for (EXTTerm *leftTerm in l.terms.allValues)
    for (EXTTerm *rightTerm in l.terms.allValues) {
        EXTTerm *targetTerm = [l findTerm:[locClass addLocation:leftTerm.location to:rightTerm.location]];
        if (targetTerm) {
            EXTMatrix *product = [EXTMatrix identity:1];
            EXTPartialDefinition *def = [EXTPartialDefinition new];
            def.inclusion = def.action = product;
            [l.multTables addPartialDefinition:def to:leftTerm.location
                                                 with:rightTerm.location];
        }
    }
    
    return l;
}

-(EXTTerm*) findTerm:(EXTLocation *)loc {
    return [terms objectForKey:loc];
}

-(void) addDifferential:(EXTDifferential*)diff {
    // first resize the differentials array if it needs it.
    while (differentials.count <= diff.page)
        differentials[differentials.count] = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *dictionary = differentials[diff.page];
    
    [dictionary setObject:diff forKey:diff.start.location];
}

-(EXTDifferential*) findDifflWithSource:(EXTLocation *)loc onPage:(int)page {
    if (page >= differentials.count)
        return nil;
    
    return [differentials[page] objectForKey:loc];
}

-(EXTDifferential*) findDifflWithTarget:(EXTLocation *)loc onPage:(int)page {
    EXTLocation *startLoc = [[loc class] reverseDiffl:loc page:page];
    return [self findDifflWithSource:startLoc onPage:page];
}

- (NSArray*)findDifflsSourcedUnderPoint:(EXTIntPoint)point onPage:(int)page {
    NSMutableArray *ret = [NSMutableArray array];
    
    if (page >= differentials.count)
        return ret;
    
    NSMutableDictionary *difflsOnPage = self.differentials[page];
    
    for (EXTLocation *loc in difflsOnPage) {
        EXTIntPoint difflPoint = [self.locConvertor gridPoint:loc];
        if (EXTEqualIntPoints(difflPoint, point))
            [ret addObject:[difflsOnPage objectForKey:loc]];
    }
    
    return ret;
}

- (NSArray*)findTermsUnderPoint:(EXTIntPoint)point {
    NSMutableArray *ret = [NSMutableArray array];
    
    for (EXTLocation *loc in terms) {
        EXTIntPoint termPoint = [self.locConvertor gridPoint:loc];
        if (EXTEqualIntPoints(termPoint, point))
            [ret addObject:[terms objectForKey:loc]];
    }
    
    return ret;
}

-(void) computeGroupsForPage:(int)page {
    if (differentials.count > page)
        for (EXTDifferential *diff in ((NSDictionary*)differentials[page]).allValues)
            [diff assemblePresentation];
    
    for (EXTTerm *term in self.terms.allValues) {
        [term updateDataForPage:page inSSeq:self];
    }
    
    return;
}

-(BOOL) isInZeroRanges:(EXTLocation*)loc {
    BOOL disjunction = false;
    
    for (EXTZeroRange* range in self.zeroRanges)
        disjunction |= [range isInRange:loc];
    
    return disjunction;
}

-(EXTSpectralSequence*) upcastToSSeq {
    return self;
}

-(void) computeLeibniz:(EXTLocation *)loc1
                  with:(EXTLocation *)loc2
                onPage:(int)page {
    [multTables computeLeibniz:loc1 with:loc2 onPage:page];
}

-(void) naivelyPropagateLeibniz:(EXTLocation*)loc page:(int)page {
    // once we have those, we should be able to do the rest.
    for (EXTTerm *t in self.terms.allValues)
        [self computeLeibniz:loc with:t.location onPage:page];
    
    return;
}

// propagates differentials along a specified lattice of EXTLocations
-(void) propagateLeibniz:(NSArray*)locations page:(int)page {
    if (locations.count == 0)
        return;
    
    CFMutableArrayRef maxes = CFArrayCreateMutable(kCFAllocatorDefault, locations.count, NULL);
    Class<EXTLocation> locClass = [(EXTLocation*)locations[0] class];
    
    // build the array of maximums
    for (int i = 0; i < locations.count; i++) {
        EXTLocation *loc = locations[i];
        for (NSInteger j = 1; true; j++) {
            EXTTerm *t = [self findTerm:loc];
            
            if (!t) {
                CFArraySetValueAtIndex(maxes, i, (void*)j);
                break;
            }
            
            loc = [[loc class] addLocation:loc to:locations[i]];
        }
    }
    
    // loop through the available differentials by incrementing an array of
    // counters.  the idea is that the counter [n0, n1, ..., nm, 0, ..., 0]
    // corresponds to the product [n0, ..., nm-1, 0, ..., 0] * em.
    CFMutableArrayRef counter = CFArrayCreateMutable(kCFAllocatorDefault, locations.count, NULL);
    for (int i = 0; i < locations.count; i++)
        CFArraySetValueAtIndex(counter, i, (void*)0);
    CFArraySetValueAtIndex(counter, 0, (void*)1);
    
    int digitalSum = 1;
    while (true) {
        // increment the counter array
        for (int i = 0; i < locations.count; i++) {
            CFArraySetValueAtIndex(counter, i, (void*)((NSInteger)CFArrayGetValueAtIndex(counter, i)+1));
            
            // check if we should perform a carry
            if (CFArrayGetValueAtIndex(counter, i) ==
                                            CFArrayGetValueAtIndex(maxes, i)) {
                CFArraySetValueAtIndex(counter, i, (void*)0);
                // and then the for(i) loop will handle the actual carry
            } else
                break;
        }
        
        // calculate the digital sum
        digitalSum = 0;
        for (int i = 0; i < locations.count; i++)
            digitalSum += (NSInteger)CFArrayGetValueAtIndex(counter, i);
        
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
            if (CFArrayGetValueAtIndex(counter, topEntry) != 0)
                break;
        
        // build the EXTLocation sum corresponding to the vector coordinate
        CFArraySetValueAtIndex(counter, topEntry, (void*)((NSInteger)CFArrayGetValueAtIndex(counter, topEntry)-1));
        EXTLocation *leftLoc = [locClass linearCombination:counter
                                               ofLocations:(__bridge CFArrayRef)(locations)];
        CFArraySetValueAtIndex(counter, topEntry, (void*)((NSInteger)CFArrayGetValueAtIndex(counter, topEntry)+1));
        
        // probably something more dramatic could happen here in the interest
        // of speed, like forcing a carry.  this will do for now, though.
        if (![self findTerm:leftLoc])
            continue;
        
        // call -computeLeibniz on (the previous sum + the shifted coordinate)
        [self computeLeibniz:leftLoc with:locations[topEntry] onPage:page];
    }
    
    // release the stuff ARC is not in charge of.
    CFRelease(maxes); CFRelease(counter);
    
    return;
}

- (int)rankOfVector:(NSArray *)vector
         inLocation:(NSObject<EXTLocation> *)loc
           actingAt:(NSObject<EXTLocation> *)otherLoc
             onPage:(int)page {
    EXTTerm *otherTerm = [self findTerm:otherLoc];
    if (!otherTerm)
        return 0;
    
    EXTMatrix *multMatrix = [self productWithLeft:loc right:otherLoc];
    
    EXTLocation *sumLoc = [self.indexClass addLocation:loc to:otherLoc];
    EXTTerm *sumTerm = self.terms[sumLoc];
    
    if (!sumTerm || !multMatrix)
        return 0;
    
    EXTMatrix *cycleMatrix = [EXTMatrix matrixWidth:((NSMutableDictionary*)otherTerm.homologyReps[page]).count height:(vector.count*otherTerm.size)];
    cycleMatrix.width = 0;
    int *cycleData = cycleMatrix.presentation.mutableBytes;
    for (NSArray *cycle in otherTerm.homologyReps[page]) {
        NSArray *hadamardResult = [EXTMatrix hadamardVectors:vector with:cycle];
        for (int j = 0; j < cycle.count; j++)
            cycleData[cycleMatrix.height*cycleMatrix.width+j] =
                                                [hadamardResult[j] intValue];
        cycleMatrix.width += 1;
    }
    
    EXTMatrix *boundaryMatrix = [EXTMatrix matrixWidth:((NSArray*)sumTerm.boundaries[page]).count height:sumTerm.size];
    boundaryMatrix.presentation = sumTerm.boundaries[page];
    return [EXTMatrix rankOfMap:[EXTMatrix newMultiply:multMatrix by:cycleMatrix] intoQuotientByTheInclusion:boundaryMatrix];
}

// tacit assumption: we don't need to run -computeGroupsForPage:
-(EXTSpectralSequence*) flattenSSeqAtPage:(int)page
                             ontoIndexing:(Class<EXTLocation>)newIndexingClass
                            viaProjection:(EXTLocation* (^)(EXTLocation*))projectionOperator {
    EXTSpectralSequence *ret = [[self class] new];
    
    // loop through the terms, projecting and summing them.
    ret.terms = [NSMutableDictionary new];
    for (EXTTerm *term in self.terms.allValues) {
        // project the term and find it in the new spectral sequence.
        EXTLocation *projectedLoc = projectionOperator(term.location);
        EXTTerm *projectedTerm = ret.terms[projectedLoc];
        if (!projectedTerm)
            ret.terms[projectedLoc] =
                (projectedTerm = [EXTTerm term:projectedLoc
                                     withNames:[NSMutableArray array]
                             andCharacteristic:defaultCharacteristic]);
        
        // flatten the term's cycles and boundaries into projectedTerm
        projectedTerm.cycles[0] = [EXTMatrix directSum:projectedTerm.cycles[0]
                                                  with:term.cycles[page]];
        projectedTerm.boundaries[0] = [EXTMatrix directSum:projectedTerm.boundaries[0]
                                                      with:term.boundaries[page]];
        [projectedTerm.names addObjectsFromArray:term.names];
    }
    
    // XXX: I am too lazy to do the multiplication tables right now. Someone
    // should come back and handle them in the future, though, in almost the
    // same way as the terms are handled above.
    
    // set up the new indexing class
    ret->indexClass = newIndexingClass;
    
    // there's probably something smarter to do here. whatever the smarter thing
    // is, it requires changing the method signature.
    ret.locConvertor = [[EXTPairToPoint alloc] init];
    // (a, b) |-> (b, a+b)
    int *internalToUserData = ((EXTPairToPoint*)ret.locConvertor).internalToUser.presentation.mutableBytes;
    internalToUserData[0*2 + 0] = 0;
    internalToUserData[0*2 + 1] = 1;
    internalToUserData[1*2 + 0] = 1;
    internalToUserData[1*2 + 1] = 1;
    
    // (s, t) |-> (t-s, s)
    int *userToScreenData = ((EXTPairToPoint*)ret.locConvertor).userToScreen.presentation.mutableBytes;
    userToScreenData[0*2 + 0] = -1;
    userToScreenData[0*2 + 1] = 1;
    userToScreenData[1*2 + 0] = 1;
    userToScreenData[1*2 + 1] = 0;
    
    // clear the differentials
    ret.differentials = [NSMutableArray new];
    
    // return the new sseq.
    return ret;
}

-(EXTMatrix*) productWithLeft:(EXTLocation*)leftLoc
                        right:(EXTLocation*)rightLoc {
    return [self.multTables getMatrixFor:leftLoc with:rightLoc];
}

@end
