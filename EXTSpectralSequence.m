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
#import "EXTterm.h"
#import "EXTdifferential.h"
#import "EXTMultiplicationTables.h"
#import "EXTMatrix.h"

@implementation EXTSpectralSequence

@synthesize terms, differentials, multTables, indexClass;

+(EXTSpectralSequence*) spectralSequence {
    EXTSpectralSequence *ret = [EXTSpectralSequence new];
    
    if (!ret)
        return nil;
    
    // and allocate the internal parts of things
    ret.terms = [NSMutableArray array];
    ret.differentials = [NSMutableArray array];
    ret.multTables = [EXTMultiplicationTables multiplicationTables:ret];
    ret.indexClass = [EXTPair class];

    return ret;
}

// returns an EXTSpectralSequence which is given by the tensor product of the
// current spectral sequence with an incoming collection of classes with
// multiplication and diff'ls.
//
// apologies about my style; you can very much tell that i'm used to working in
// a language with strong typing and an easy production of tuple types, neither
// of which is quite true in Objective-C.  i'm not about to make a zillion
// helper classes, though.
-(EXTSpectralSequence*) tensorWithSSeq:(EXTSpectralSequence *)p {
    // what we'll eventually be returning.
    EXTSpectralSequence *ret = [EXTSpectralSequence spectralSequence];

    NSMutableArray *tensorTerms = [NSMutableArray array];
    
    // we need to do a bunch of manipulations over pairs of classes.
    for (EXTTerm *t1 in self.terms) {
        for (EXTTerm *t2 in p.terms) {
            // build EXTTerm's for all the tensor pairs A (x) P, and store
            // these in a separate list.
            EXTLocation *loc = [[t1.location class] addLocation:t1.location
                                                             to:t2.location];
            NSMutableArray *names = [NSMutableArray array];
            for (int i = 0; i < t1.names.count; i++)
                for (int j = 0; j < t2.names.count; j++)
                    [names addObject:[NSString stringWithFormat:@"%@ %@", t1.names[i], t2.names[j]]];
            
            EXTTerm *t1t2 = [EXTTerm term:loc andNames:names];
            
            [tensorTerms addObject:@[t1t2, t1, t2, @false]];
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
        for (NSMutableArray *workingTerm in tensorTerms)
            if ([[(EXTTerm*)workingTerm[0] location] isEqual:loc])
                [atThisLoc addObject:workingTerm];
        
        // now, we sum them together. we want a list of names.
        NSMutableArray *sumNames = [NSMutableArray array];
        for (NSMutableArray *workingTerm in atThisLoc)
            [sumNames addObjectsFromArray:((EXTTerm*)workingTerm[0]).names];
        
        // finally, add the summed term and its child terms to the spliced terms
        [splicedTensorTerms addObject:@[[EXTTerm term:loc andNames:sumNames], atThisLoc]];
    }
    
    // store these terms into the returning spectral sequence.
    for (NSMutableArray* tuple in splicedTensorTerms) {
        [ret.terms addObject:tuple[0]];
    }
    
    // XXX: i don't think that this is **summing** differentials correctly...
    NSMutableArray *outputDifferentials = [NSMutableArray array];
    // iterate over pairs of existing terms to build differentials from old ones
    for (NSMutableArray *tuple in splicedTensorTerms) {
        EXTTerm *start = tuple[0];
        NSMutableArray *startSummands = tuple[1];
        
        // find all the differentials involving any of the working left-summands
        NSMutableArray *partialPresentations = [NSMutableArray array];
        for (EXTDifferential *d1 in self.differentials) {
            // check if this diff'l is attached to one of our left-summands.
            int sourceIndex = -1, sourceOffset = 0;
            for (int i = 0; i < startSummands.count; i++) {
                NSMutableArray *tuple = startSummands[i];
                if (tuple[1] == d1.start) {
                    sourceIndex = i;
                    break;
                }
                sourceOffset += ((EXTTerm*)tuple[1]).names.count;
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
                    endOffset += ((EXTTerm*)tuple[0]).names.count;
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
            EXTMatrix *idP = [EXTMatrix identity:P.names.count];
            EXTMatrix *i1 = [EXTMatrix includeEvenlySpacedBasis:AP.names.count endDim:start.names.count offset:sourceOffset spacing:1];
            EXTMatrix *i2 = [EXTMatrix includeEvenlySpacedBasis:BP.names.count endDim:end.names.count offset:endOffset spacing:1];
            
            // now we iterate through the available i and d.
            NSMutableArray *partialsForThisD = [NSMutableArray array];
            for (EXTPartialDefinition *partial in d1.partialDefinitions) {
                EXTPartialDefinition *newPartial = [EXTPartialDefinition new];
                EXTMatrix *ix1 = [EXTMatrix hadamardProduct:partial.inclusion with:idP];
                EXTMatrix *dx1 = [EXTMatrix hadamardProduct:partial.differential with:idP];
                newPartial.inclusion = [EXTMatrix newMultiply:i1 by:ix1];
                newPartial.differential = [EXTMatrix newMultiply:i2 by:dx1];
                [partialsForThisD addObject:partial];
            }
            
            [partialPresentations addObject:[NSMutableArray arrayWithObjects:start, end, @(d1.page), partialsForThisD, @false, nil]];
        } // d1
        
        // now also do d2.
        // XXX: THIS IS DUPLICATED CODE. BUGS IN ONE MEAN BUGS IN THE OTHER.
        // CORRECT APPROPRIATELY, AND EVENTUALLY FACTOR THIS ALL OUT.
        for (EXTDifferential *d2 in p.differentials) {
            // check if this diff'l is attached to one of our right-summands.
            int sourceIndex = -1, sourceOffset = 0;
            for (int i = 0; i < startSummands.count; i++) {
                NSMutableArray *tuple = startSummands[i];
                if (tuple[2] == d2.start) {
                    sourceIndex = i;
                    break;
                }
                sourceOffset += ((EXTTerm*)tuple[2]).names.count;
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
                    endOffset += ((EXTTerm*)tuple[0]).names.count;
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
            EXTMatrix *idA = [EXTMatrix identity:A.names.count];
            EXTMatrix *i1 = [EXTMatrix includeEvenlySpacedBasis:AP.names.count endDim:start.names.count offset:sourceOffset spacing:1];
            EXTMatrix *i2 = [EXTMatrix includeEvenlySpacedBasis:AQ.names.count endDim:end.names.count offset:endOffset spacing:1];
            
            // now we iterate through the available i and d.
            NSMutableArray *partialsForThisD = [NSMutableArray array];
            for (EXTPartialDefinition *partial in d2.partialDefinitions) {
                EXTPartialDefinition *newPartial = [EXTPartialDefinition new];
                EXTMatrix *ix1 = [EXTMatrix hadamardProduct:idA with:partial.inclusion];
                EXTMatrix *dx1 = [EXTMatrix hadamardProduct:idA with:partial.differential];
                newPartial.inclusion = [EXTMatrix newMultiply:i1 by:ix1];
                newPartial.differential = [EXTMatrix newMultiply:i2 by:dx1];
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
            
            [outputDifferentials addObject:diff];
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
                *leftEntry = [self.multTables performSoftLookup:A.location with:B.location],
                *rightEntry = [p.multTables performSoftLookup:P.location with:Q.location];
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
                    } else CRoffset += ((EXTTerm*)(subTuple[0])).names.count;
                }
                if (CR) break;
                CRoffset = 0;
            }
            
            int BQoffset = 0;
            for (int i = 0; i < [rightSummands indexOfObject:rightSummand]; i++)
                BQoffset += ((EXTTerm*)(rightSummands[i])).names.count;
            
            // while we're at it, build the inclusion matrix C|R --> (+) C|R
            EXTMatrix *i2 = [EXTMatrix includeEvenlySpacedBasis:CR.names.count endDim:CRplus.names.count offset:CRoffset spacing:1];
            
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
                EXTMatrix *i1 = [EXTMatrix matrixWidth:(A.names.count*B.names.count*P.names.count*Q.names.count) height:(leftTerm.names.count*rightTerm.names.count)];
                
                for (int i = 0; i < A.names.count; i++)
                for (int j = 0; j < P.names.count; j++)
                for (int k = 0; k < B.names.count; k++)
                for (int l = 0; l < Q.names.count; l++) {
                    int APskip = B.names.count*Q.names.count*([leftSummands indexOfObject:leftSummand] + i*P.names.count + j);
                    // poke a 1 in at this location.  the only way to see that
                    // this is a reasonable thing to do is to draw out an
                    // example.  i'm very sorry. :(
                    ((NSMutableArray*)(i1.presentation[l+Q.names.count*(j+P.names.count*(k+i*B.names.count))]))[APskip + BQoffset + k*Q.names.count + l] = @1;
                }
                
                // now, we use this to build the differential presentation.
                tensorPartial.differential = [EXTMatrix newMultiply:i1 by:[EXTMatrix hadamardProduct:leftPartial.differential with:rightPartial.differential]];
                
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
    return [self tensorWithSSeq:[EXTSpectralSequence buildLaurentSSeq:name location:loc upTo:upTo downTo:downTo]];
}

+(EXTSpectralSequence*) buildLaurentSSeq:(NSString*)name location:(EXTLocation*)loc upTo:(int)upTo downTo:(int)downTo {
    Class<EXTLocation> locClass = [loc class];
    EXTSpectralSequence *l = [EXTSpectralSequence spectralSequence];
    
    // construct a bunch of terms
    for (int i = downTo; i <= upTo; i++) {
        // TODO: possibly there's a better way to name these classes. at the
        // moment, i've opted to name them for easy LaTeX printing.
        EXTLocation *workingLoc = [locClass scale:loc by:i];
        EXTTerm *workingTerm = [EXTTerm term:workingLoc andNames:
                                [NSMutableArray arrayWithObject:
                                 [NSString stringWithFormat:@"(%@)^{%d}",
                                  name, i]]];
        [l.terms addObject:workingTerm];
    }
    
    // now we throw in the internal multiplicative structure
    for (EXTTerm *leftTerm in l.terms)
    for (EXTTerm *rightTerm in l.terms) {
        EXTTerm *targetTerm = [l findTerm:[locClass addLocation:leftTerm.location to:rightTerm.location]];
        if (targetTerm) {
            EXTMatrix *product = [EXTMatrix identity:1];
            EXTPartialDefinition *def = [EXTPartialDefinition new];
            def.inclusion = def.differential = product;
            [l.multTables addPartialDefinition:def to:leftTerm.location
                                                 with:rightTerm.location];
        }
    }
    
    return l;
}

+(EXTSpectralSequence*) sSeqWithUnit:(Class<EXTLocation>)locClass {
    return [EXTSpectralSequence buildLaurentSSeq:@"1" location:[locClass identityLocation] upTo:0 downTo:0];
}

-(EXTTerm*) findTerm:(EXTLocation *)loc {
    for (EXTTerm *term in self.terms) {
        if ([loc isEqual:[term location]])
            return term;
    }
    
    return nil;
}

-(EXTDifferential*) findDifflWithSource:(EXTLocation *)loc onPage:(int)page {
    for (EXTDifferential *diffl in self.differentials)
        if ([[[diffl start] location] isEqual:loc] && ([diffl page] == page))
            return diffl;
    
    return nil;
}

-(EXTDifferential*) findDifflWithTarget:(EXTLocation *)loc onPage:(int)page {
    for (EXTDifferential *diffl in self.differentials)
        if (([[[diffl end] location] isEqual:loc]) && ([diffl page] == page))
            return diffl;
    
    return nil;
}

-(void) computeGroupsForPage:(int)page {
    for (EXTTerm *term in self.terms) {
        [term computeCycles:page
          differentialArray:self.differentials];
        [term computeBoundaries:page
              differentialArray:self.differentials];
    }
    
    return;
}

#pragma mark - built-in demos

+(EXTSpectralSequence*) workingDemo {
    return [EXTSpectralSequence KUhC2Demo];
}

+(EXTSpectralSequence*) ladderDemo {
    EXTSpectralSequence *ret = [EXTSpectralSequence spectralSequence];
    
    EXTTerm *start = [EXTTerm term:[EXTPair pairWithA:1 B:0] andNames:[NSMutableArray arrayWithObject:@"e"]],
            *end = [EXTTerm term:[EXTPair pairWithA:0 B:1] andNames:[NSMutableArray arrayWithObject:@"x"]];
    
    [ret.terms addObjectsFromArray:@[start, end]];
    
    EXTDifferential *diff = [EXTDifferential differential:start end:end page:1];
    EXTPartialDefinition *partial = [EXTPartialDefinition new];
    EXTMatrix *mat = [EXTMatrix identity:1];
    partial.inclusion = partial.differential = mat;
    [diff.partialDefinitions addObject:partial];
    [ret.differentials addObject:diff];
    
    ret = [ret tensorWithPolyClass:@"eta" location:[EXTPair pairWithA:1 B:1] upTo:5];
    
    return ret;
}

+(EXTSpectralSequence*) A1MSSDemo {
    EXTSpectralSequence *ret = [EXTSpectralSequence sSeqWithUnit:[EXTTriple class]];
    
    // add the three polynomial generators to the sseq: h10, h11, h20
    ret = [ret tensorWithPolyClass:@"h10" location:[EXTTriple tripleWithA:0 B:1 C:0] upTo:3];
    ret = [ret tensorWithPolyClass:@"h11" location:[EXTTriple tripleWithA:1 B:1 C:1] upTo:3];
    ret = [ret tensorWithPolyClass:@"h20" location:[EXTTriple tripleWithA:2 B:1 C:0] upTo:3];
    
    // d1(h20) = h10 h11
    
    // d3(h20^2) = h11^3
    
    return ret;
}

+(EXTSpectralSequence*) KUhC2Demo {
    EXTSpectralSequence *ret = [EXTSpectralSequence sSeqWithUnit:[EXTPair class]];
    
    ret = [ret tensorWithLaurentClass:@"beta^2"
                             location:[EXTPair pairWithA:4 B:0]
                                 upTo:5
                               downTo:-4];
    ret = [ret tensorWithPolyClass:@"eta"
                          location:[EXTPair pairWithA:1 B:1]
                              upTo:12];
    
    // not allowed to do computations with differentials on pages which you
    // haven't yet seen.
    [ret computeGroupsForPage:0];
    [ret computeGroupsForPage:1];
    [ret computeGroupsForPage:2];
    
    // there are three d3 differentials...
    
    // d3(beta^2) = eta^3
    EXTTerm *beta2 = [ret findTerm:[EXTPair pairWithA:4 B:0]];
    EXTDifferential *diff = [EXTDifferential differential:beta2 end:[ret findTerm:[EXTPair pairWithA:3 B:3]] page:3];
    EXTPartialDefinition *diffdefn = [EXTPartialDefinition new];
    EXTMatrix *one = [EXTMatrix identity:1];
    diffdefn.differential = diffdefn.inclusion = one;
    [diff.partialDefinitions addObject:diffdefn];
    [ret.differentials addObject:diff];
    
    // d3(eta) = 0
    EXTTerm *eta = [ret findTerm:[EXTPair pairWithA:1 B:1]];
    EXTDifferential *diff2 = [EXTDifferential differential:eta end:[ret findTerm:[EXTPair pairWithA:0 B:4]] page:3];
    EXTPartialDefinition *diff2defn = [EXTPartialDefinition new];
    EXTMatrix *zero = [EXTMatrix matrixWidth:1 height:1];
    diff2defn.differential = zero;
    diff2defn.inclusion = one;
    [diff2.partialDefinitions addObject:diff2defn];
    [ret.differentials addObject:diff2];
    
    // d3(beta^-2) = beta^-4 eta^3
    EXTTerm *betaneg2 = [ret findTerm:[EXTPair pairWithA:-4 B:0]];
    EXTDifferential *diff3 = [EXTDifferential differential:betaneg2 end:[ret findTerm:[EXTPair pairWithA:-5 B:3]] page:3];
    EXTPartialDefinition *diff3defn = [EXTPartialDefinition new];
    diff3defn.differential = one;
    diff3defn.inclusion = one;
    [diff3.partialDefinitions addObject:diff3defn];
    [ret.differentials addObject:diff3];
    
    // propagate NAIVELY using the Leibniz rule
    for (EXTTerm *term in ret.terms)
        [ret.multTables computeLeibniz:[eta location]
                                  with:[term location]
                                onPage:3];
    for (EXTTerm *term in ret.terms)
        [ret.multTables computeLeibniz:[beta2 location]
                                  with:[term location]
                                onPage:3];
    for (int i = ret.terms.count - 1; i >= 0; i--) {
        EXTTerm *term = ret.terms[i];
        [ret.multTables computeLeibniz:[betaneg2 location]
                                  with:[term location]
                                onPage:3];
    }
    
    return ret;
}

+(EXTSpectralSequence*) randomDemo {
    EXTSpectralSequence *ret = [EXTSpectralSequence spectralSequence];
    
    // XXX: this doesn't catch collisions.
    for (int i = 0; i < 40; i++) {
        EXTPair *location =
                    [EXTPair pairWithA:(arc4random()%30) B:(arc4random()%30)];
        NSArray *names = nil;
        
        if ((location.a < 2) || (location.b < 5))
            continue;
        
        switch ((arc4random()%7)+1) {
            case 1:
                names = @[@"x"];
                break;
            case 2:
                names = @[@"x", @"y"];
                break;
            case 3:
                names = @[@"x", @"y", @"z"];
                break;
            case 4:
                names = @[@"x", @"y", @"z", @"s"];
                break;
            case 5:
                names = @[@"x", @"y", @"z", @"s", @"t"];
                break;
            case 6:
                names = @[@"x", @"y", @"z", @"s", @"t", @"u"];
                break;
            case 7:
            default:
                names = @[@"x", @"y", @"z", @"s", @"t", @"u", @"v"];
                break;
        }
        
        EXTTerm *term = [EXTTerm term:location andNames:[NSMutableArray arrayWithArray:names]];
        
        [ret.terms addObject:term];
    }
    
    return ret;
}

+(EXTSpectralSequence*) S5Demo {
    EXTSpectralSequence *ret = [EXTSpectralSequence spectralSequence];
    
    // add the terms in the SSS for S^1 --> S^5 --> CP^2
    EXTTerm *e   = [EXTTerm term:[EXTPair pairWithA:1 B:0]
                        andNames:[NSMutableArray arrayWithArray:@[@"e"]]],
    *x   = [EXTTerm term:[EXTPair pairWithA:0 B:2]
                andNames:[NSMutableArray arrayWithArray:@[@"x"]]],
    *ex  = [EXTTerm term:[EXTPair pairWithA:1 B:2]
                andNames:[NSMutableArray arrayWithArray:@[@"ex"]]],
    *x2  = [EXTTerm term:[EXTPair pairWithA:0 B:4]
                andNames:[NSMutableArray arrayWithArray:@[@"x2"]]],
    *ex2 = [EXTTerm term:[EXTPair pairWithA:1 B:4]
                andNames:[NSMutableArray arrayWithArray:@[@"ex2"]]],
    *one = [EXTTerm term:[EXTPair pairWithA:0 B:0]
                andNames:[NSMutableArray arrayWithArray:@[@"1"]]];
    
    [ret.terms addObjectsFromArray:@[one,e,x,ex,x2,ex2]];
    
    // you're not allowed to add differentials to pages which you haven't "seen"
    [ret computeGroupsForPage:0];
    [ret computeGroupsForPage:1];
    [ret computeGroupsForPage:2];
    
    // add a single differential
    EXTDifferential *firstdiff = [EXTDifferential differential:e end:x page:2];
    EXTPartialDefinition *firstpartial = [EXTPartialDefinition new];
    EXTMatrix *inclusion = [EXTMatrix matrixWidth:1 height:1];
    EXTMatrix *differential = [EXTMatrix matrixWidth:1 height:1];
    [[inclusion.presentation objectAtIndex:0] setObject:@1 atIndex:0];
    [[differential.presentation objectAtIndex:0] setObject:@1 atIndex:0];
    firstpartial.inclusion = inclusion;
    firstpartial.differential = differential;
    firstdiff.partialDefinitions[0] = firstpartial;
    [ret.differentials addObject:firstdiff];
    
    // TODO: need to assemble the cycle groups for lower pages first...
    [firstdiff assemblePresentation]; // test!
    
    // specify the multiplicative structure
    EXTMatrix *matrix = [EXTMatrix matrixWidth:1 height:1];
    [matrix.presentation[0] setObject:@1 atIndex:0];
    EXTPartialDefinition *partialDefinition = [EXTPartialDefinition new];
    partialDefinition.inclusion = matrix;
    partialDefinition.differential = matrix;
    [ret.multTables addPartialDefinition:partialDefinition to:[e location] with:[x location]];
    [ret.multTables addPartialDefinition:partialDefinition to:[ex location] with:[x location]];
    [ret.multTables addPartialDefinition:partialDefinition to:[e location] with:[x2 location]];
    [ret.multTables addPartialDefinition:partialDefinition to:[x location] with:[e location]];
    [ret.multTables addPartialDefinition:partialDefinition to:[x location] with:[ex location]];
    [ret.multTables addPartialDefinition:partialDefinition to:[x2 location] with:[e location]];
    [ret.multTables addPartialDefinition:partialDefinition to:[x location] with:[x location]];
    
    [ret.multTables computeLeibniz:[e location] with:[x location] onPage:2];
    
    return ret;
}

@end
