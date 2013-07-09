//
//  EXTMaySpectralSequence.m
//  Ext Chart
//
//  Created by Eric Peterson on 7/9/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTMaySpectralSequence.h"
#import "EXTTriple.h"

@implementation EXTMaySpectralSequence

/*
 EXTTriple *h10 = [EXTTriple tripleWithA:1 B:1 C:1],
           *h11 = [EXTTriple tripleWithA:1 B:2 C:1],
           *h20 = [EXTTriple tripleWithA:1 B:3 C:2];
*/

+(EXTMaySpectralSequence*) fillToWidth:(int)width {
    EXTMaySpectralSequence *sseq = (EXTMaySpectralSequence*)[EXTMaySpectralSequence sSeqWithUnit:[EXTTriple class]];
    
    // start by adding the polynomial terms h_{i,j}
    for (int i = 1; ; i++) {
        
        // if we've passed outside of the width, then quit.
        if ((1 << i)-2 > width)
            break;
        
        for (int j = 0; ; j++) {
            // calculate the location of the present term
            int A = 1, B = (1 << j)*((1 << i) - 1), C = i;
            if (B - 1 > width)
                break;
            
            int limit = ((i == 1) && (j == 0)) ? width : width/(B-1);
            
            [sseq addPolyClass:[NSString stringWithFormat:@"h_{%d,%d}",i,j] location:[EXTTriple tripleWithA:A B:B C:C] upTo:limit];
        }
    }
    
    // xi_i^{2^j} has degree (1, 2^j(2^i - 1), i)  |->  (2^j(2^i-1) - 1, 1)
    // then add their d1 differentials
    // then propagate with nakamura's lemma until exhausted
    
    return sseq;
}

@end
