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
    EXTSpectralSequence *ret = [[EXTSpectralSequence alloc] init];
    
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

    // finally, sum up all the terms which share a given EXTLocation.  add them to a *new* list --- this is the one you'll be storing for return.
    
    return nil;
}

-(EXTSpectralSequence*) tensorSSeqs:(EXTSpectralSequence *)p {
    return [self tensorWithClasses:p.terms
                     differentials:p.differentials
                        multTables:p.multTables];
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

@end
