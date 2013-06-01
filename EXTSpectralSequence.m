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
        
        // find all the differentials involving any of the summands of this term
        NSMutableArray *blockPresentations = [NSMutableArray array];
        for (EXTDifferential *d1 in self.differentials) {
            // check if this diff'l is attached to one of our summands.
            bool keepGoing = false;
            for (NSMutableArray *tuple in startSummands)
                if (tuple[1] == d1.start)
                    keepGoing = true;
            if (!keepGoing)
                continue;
            
            // we also need a differential on the right.
            for (EXTDifferential *d2 in newDifferentials) {
                // check if *that* diff'l is also attached.
                bool keepGoing = false;
                for (NSMutableArray *tuple in startSummands)
                    if (tuple[2] == d2.start)
                        keepGoing = true;
                if (!keepGoing || (d1.page != d2.page)) // and that pages match.
                    continue;
                
                // ok, so we have a pair of differentials sourced at start, and
                // they're on the same page.  now we need to actually sum them,
                // which means producing a matrix, which means knowing the dim
                // of the target term.  find it now.
                NSMutableArray *targetTuple = nil;
                EXTLocation *targetLoc = [start.location.class followDiffl:start.location page:d1.page];
                for (NSMutableArray *testTuple in splicedTensorTerms) {
                    if (((EXTTerm*)testTuple[0]).location == targetLoc)
                        targetTuple = testTuple;
                }
                EXTTerm *end = targetTuple[0];
                NSMutableArray *endSummands = targetTuple[1];
                
                // to build a presenting matrix, we need to know the offset of
                // each term, to find its position among the direct summands.
                int startOffset = 0, endOffsetLeft = 0, endOffsetRight = 0;
                for (int i = 0;
                     (((NSMutableArray*)startSummands[i])[1] != d1.start) ||
                     (((NSMutableArray*)startSummands[i])[2] != d2.start);
                     i++) {
                    NSMutableArray *workingTuple = splicedTensorTerms[i];
                    EXTTerm *workingTerm = workingTuple[0];
                    startOffset += workingTerm.names.count;
                }
                for (int i = 0;
                     ((NSMutableArray*)endSummands[i])[2] != d2.end;
                     i++) {
                    NSMutableArray *workingTuple = splicedTensorTerms[i];
                    EXTTerm *workingTerm = workingTuple[0];
                    endOffsetLeft += workingTerm.names.count;
                }
                for (int i = 0;
                     ((NSMutableArray*)endSummands[i])[1] != d1.end;
                     i++) {
                    NSMutableArray *workingTuple = splicedTensorTerms[i];
                    EXTTerm *workingTerm = workingTuple[0];
                    endOffsetRight += workingTerm.names.count;
                }
                
                // use the rule d(a|p) = da|p + a|dp to build a presentation.
                EXTMatrix *presentation =
                    [EXTMatrix matrixWidth:start.names.count
                                    height:end.names.count];
                // first build the hadamard product for the first summand...
                for (int i = 0; i < d1.start.names.count; i++) //col1
                    for (int j = 0; j < d2.start.names.count; j++) //col2
                        for (int k = 0; k < d1.end.names.count; k++) //row1
                            for (int l = 0; l < d2.end.names.count; l++) { //row2
                                // get the value
                                int value = [((NSMutableArray*)d1.presentation.presentation[i])[k] intValue];
                                if (j != l) value = 0;
                                // get the column
                                NSMutableArray *col = [presentation.presentation objectAtIndex:(endOffsetLeft + d2.end.names.count*k + l)];
                                [col setObject:@(value) atIndexedSubscript:(startOffset + i*d2.start.names.count + j)];
                                // set the row
                            }
                // and the second hadamard product for the second...
                for (int i = 0; i < d1.start.names.count; i++) //col1
                    for (int j = 0; j < d2.start.names.count; j++) //col2
                        for (int k = 0; k < d1.end.names.count; k++) //row1
                            for (int l = 0; l < d2.end.names.count; l++) { //row2
                                // get the value
                                int value = [((NSMutableArray*)d2.presentation.presentation[j])[l] intValue];
                                if (i != k) value = 0;
                                // get the column
                                NSMutableArray *col = [presentation.presentation objectAtIndex:(endOffsetRight + d2.end.names.count*k + l)];
                                [col setObject:@(value) atIndexedSubscript:(startOffset + i*d2.start.names.count + j)];
                                // set the row
                            }
                
                // store it to a list of presentations, along with its page
                [blockPresentations addObject:@[@(d1.page), @false, presentation, start, end]];
            }
        }
        
        // sum up all the instances of each page and construct an EXTDiff'l
        NSMutableArray *summedDifferentials = [NSMutableArray array];
        for (NSMutableArray *diffEntry in blockPresentations) {
            // if we've already touched this presentation, then skip it.
            if ([diffEntry[1] isEqual:@true])
                continue;
            
            // otherwise, we have a fresh presentation.  we should find every
            // other presentation that shares its page and sum them.
            EXTMatrix *presentation = [EXTMatrix matrixWidth:[((EXTMatrix*)diffEntry[2]).presentation count] height:[[((EXTMatrix*)diffEntry[2]).presentation objectAtIndex:0] count]];
            for (NSMutableArray *workingEntry in blockPresentations) {
                // only work with presentations on this page.
                if ([diffEntry[0] isNotEqualTo:workingEntry[0]])
                    continue;
                
                for (int i = 0; i < presentation.presentation.count; i++) {
                    NSMutableArray *cumArray = presentation.presentation[i];
                    NSMutableArray *workingArray = ((EXTMatrix*)workingEntry[2]).presentation[i];
                    
                    for (int j = 0; j < cumArray.count; j++)
                        cumArray[j] = @([cumArray[j] intValue] + [workingArray[j] intValue]);
                }
                
                // tag this presentation as finished.
                [workingEntry setObject:@true atIndexedSubscript:1];
            }
            
            EXTDifferential *diffl = [EXTDifferential differential:diffEntry[3] end:diffEntry[4] page:[diffEntry[0] intValue]];
            EXTPartialDefinition *partial = [EXTPartialDefinition new];
            partial.differential = diffEntry[2];
            partial.inclusion = [EXTMatrix identity:partial.differential.width];
            
            [summedDifferentials addObject:diffl];
        }
        
        // store to the output array of differentials
        [outputDifferentials addObjectsFromArray:summedDifferentials];
    }
    
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
