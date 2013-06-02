//
//  EXTSpectralSequence.m
//  Ext Chart
//
//  Created by Eric Peterson on 5/31/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTSpectralSequence.h"
#import "EXTPair.h"
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
-(EXTSpectralSequence*) tensorWithClasses:(NSMutableArray*)newClasses
                            differentials:(NSMutableArray*)newDifferentials
                               multTables:(EXTMultiplicationTables*)newTables {
    NSMutableArray *tensorTerms = [NSMutableArray array];
    
    // we need to do a bunch of manipulations over pairs of classes.
    for (EXTTerm *t1 in self.terms) {
        for (EXTTerm *t2 in newClasses) {
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
                    *A = ((NSMutableArray*)startSummands[sourceIndex])[1],
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
            
            EXTTerm *BP = ((NSMutableArray*)endSummands[endIndex])[0],
                    *B = ((NSMutableArray*)endSummands[endIndex])[1];
            
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
        for (EXTDifferential *d2 in newDifferentials) {
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
                     *A = ((NSMutableArray*)startSummands[sourceIndex])[1],
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
                    if ((tuple[1] == A) && (tuple[2] == d2.end)) {
                        endIndex = i;
                        break;
                    }
                    endOffset += ((EXTTerm*)tuple[0]).names.count;
                }
                
                if (endIndex != -1)
                    break;
            }
            
            EXTTerm *AQ = ((NSMutableArray*)endSummands[endIndex])[0],
                    *Q = ((NSMutableArray*)endSummands[endIndex])[2];
            
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
    } // splicedVectorTerms
    
    // iterate over pairs of of pairs of existing terms...
    // ... and use the old multiplication tables to build new ones, via the rule (a|p)(a'|p') = (aa')|(pp')
    // XXX: i'm skipping this for now.

    // now that we have all this data laying around, it's time to package it
    // into an EXTSpectralSequence and return.
    EXTSpectralSequence *ret = [EXTSpectralSequence spectralSequence];
    for (NSMutableArray* tuple in splicedTensorTerms) {
        [ret.terms addObject:tuple[0]];
    }
    
    ret.differentials = outputDifferentials;
    
    return ret;
}

-(EXTSpectralSequence*) tensorWithSSeq:(EXTSpectralSequence *)p {
    return [self tensorWithClasses:p.terms
                     differentials:p.differentials
                        multTables:p.multTables];
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
    Class<EXTLocation> locClass = [loc class];
    EXTSpectralSequence *l = [EXTSpectralSequence spectralSequence];
    
    // construct a bunch of terms
    for (int i = downTo; i <= upTo; i++) {
        // TODO: possibly there's a better way to name these classes. at the
        // moment, i've opted to name them for easy LaTeX printing.
        EXTLocation *workingLoc = [locClass scale:loc by:i];
        EXTTerm *workingTerm = [EXTTerm term:workingLoc andNames:
                                [NSMutableArray arrayWithObject:
                                 [NSString stringWithFormat:@"{%@}^{%d}",
                                                            name, i]]];
        [l.terms addObject:workingTerm];
    }
    
    // they have no differentials among them, so skip that.
    // but! they do have a multiplicative structure:
    EXTMultiplicationTables *newTables =
                            [EXTMultiplicationTables multiplicationTables:l];
    // XXX: i'm skipping this for now.
    
    // pass this toward the tensor routine
    return [self tensorWithSSeq:l];
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
        if (([[diffl start] location] == loc) && ([diffl page] == page))
            return diffl;
    
    return nil;
}

-(EXTDifferential*) findDifflWithTarget:(EXTLocation *)loc onPage:(int)page {
    for (EXTDifferential *diffl in self.differentials)
        if (([[diffl end] location] == loc) && ([diffl page] == page))
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

+(EXTSpectralSequence*) KUhC2Demo {
    EXTSpectralSequence *ret = [EXTSpectralSequence spectralSequence];
    
    [ret.terms addObject:[EXTTerm term:[EXTPair identityLocation] andNames:[NSMutableArray arrayWithObject:@"1"]]];
    ret = [ret tensorWithLaurentClass:@"beta^2" location:[EXTPair pairWithA:4 B:0] upTo:5 downTo:-5];
    ret = [ret tensorWithPolyClass:@"eta" location:[EXTPair pairWithA:1 B:1] upTo:10];
    
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
