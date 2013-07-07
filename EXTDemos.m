//
//  EXTDemos.m
//  Ext Chart
//
//  Created by Eric Peterson on 7/7/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTDemos.h"
#import "EXTPolynomialSSeq.h"
#import "EXTdifferential.h"
#import "EXTterm.h"

@implementation EXTDemos

+(EXTSpectralSequence*) workingDemo {
    return [EXTDemos A1MSSModernDemo];
}

+(EXTSpectralSequence*) A1MSSModernDemo {
    EXTPolynomialSSeq *sseq = [EXTPolynomialSSeq sSeqWithUnit:[EXTTriple class]];
    
    return sseq;
}

+(EXTSpectralSequence*) ladderDemo {
    EXTSpectralSequence *ret = [EXTSpectralSequence spectralSequence];
    
    EXTTerm *start = [EXTTerm term:[EXTPair pairWithA:1 B:0] andNames:[NSMutableArray arrayWithObject:@"e"]],
    *end = [EXTTerm term:[EXTPair pairWithA:0 B:1] andNames:[NSMutableArray arrayWithObject:@"x"]];
    
    ret.terms = [NSMutableDictionary dictionaryWithObjects:@[start, end] forKeys:@[start.location, end.location]];
    
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
    ret = [ret tensorWithPolyClass:@"h10" location:[EXTTriple tripleWithA:1 B:1 C:1] upTo:8];
    ret = [ret tensorWithPolyClass:@"h11" location:[EXTTriple tripleWithA:1 B:2 C:1] upTo:8];
    ret = [ret tensorWithPolyClass:@"h20" location:[EXTTriple tripleWithA:1 B:3 C:2] upTo:4];
    
    // set up the zero range.  TODO: this should come before the tensor calls,
    // and they should handle it well. :)
    [ret.zeroRanges addObject:[EXTZeroRangeStrict newWithSSeq:ret]];
    
    // some basic partial definitions
    EXTPartialDefinition *diffone = [EXTPartialDefinition new];
    EXTMatrix *one = [EXTMatrix identity:1];
    diffone.differential = diffone.inclusion = one;
    
    EXTTriple *h10 = [EXTTriple tripleWithA:1 B:1 C:1],
    *h11 = [EXTTriple tripleWithA:1 B:2 C:1],
    *h20 = [EXTTriple tripleWithA:1 B:3 C:2];
    
    // d1(h20) = h10 h11
    EXTDifferential *diff = [EXTDifferential differential:[ret findTerm:h20] end:[ret findTerm:[EXTTriple followDiffl:h20 page:1]] page:1];
    [diff.partialDefinitions addObject:diffone];
    [ret.differentials addObject:diff];
    // d1(h11) = 0 is automatic.
    // d1(h10) = 0 is automatic.
    
    // now, do leibniz propagation.
    [ret.multTables propagateLeibniz:@[h20, h10, h11] page:1];
    
    // d3(h20^2) = h11^3
    EXTLocation *h20squared = [[h20 class] scale:h20 by:2];
    EXTDifferential *diff2 = [EXTDifferential differential:[ret findTerm:h20squared] end:[ret findTerm:[[h11 class] scale:h11 by:3]] page:2];
    [diff2.partialDefinitions addObject:diffone];
    [ret.differentials addObject:diff2];
    
    // leibniz again, on the new terms.
    [ret.multTables propagateLeibniz:@[h10, h11, h20squared] page:2];
    
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
    
    [ret.multTables propagateLeibniz:@[[eta location], [beta2 location], [betaneg2 location]] page:3];
    
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
        
        [ret.terms setObject:term forKey:term.location];
    }
    
    return ret;
}

+(EXTSpectralSequence*) S5Demo {
    EXTSpectralSequence *ret = [EXTSpectralSequence spectralSequence];
    
    [ret.zeroRanges addObject:[EXTZeroRangeStrict newWithSSeq:ret]];
    
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
    
    ret.terms = [NSMutableDictionary dictionaryWithObjects:@[one,e,x,ex,x2,ex2] forKeys:@[one.location,e.location,x.location,ex.location,x2.location,ex2.location]];
    
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
