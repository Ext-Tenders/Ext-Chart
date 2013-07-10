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

@interface EXTMayTag : NSObject <NSCopying>
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
@end




@implementation EXTMaySpectralSequence

+(EXTMaySpectralSequence*) fillToWidth:(int)width {
    EXTMaySpectralSequence *sseq = (EXTMaySpectralSequence*)[EXTMaySpectralSequence sSeqWithUnit:[EXTTriple class]];
    
    [sseq.zeroRanges addObject:[EXTZeroRangeStrict newWithSSeq:sseq]];
    
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
            
            [sseq addPolyClass:[EXTMayTag tagWithI:i J:j] location:[EXTTriple tripleWithA:A B:B C:C] upTo:limit];
        }
    }
    
    // then add their d1 differentials
    for (int index = 0; index < sseq.names.count; index++) {
        EXTMayTag *tag = sseq.names[index];
        int i = tag.i, j = tag.j;
        
        // these elements are genuinely primitive, so never support diff'ls.
        if (i == 1)
            continue;
        
        EXTTriple *location = sseq.locations[index];
        EXTTerm *target = [sseq findTerm:[EXTTriple followDiffl:location page:1]];
        EXTDifferential *diff = [EXTDifferential differential:[sseq findTerm:location] end:target page:1];
        EXTPartialDefinition *partial = [EXTPartialDefinition new];
        partial.inclusion = [EXTMatrix identity:1];
        partial.differential = [EXTMatrix matrixWidth:1 height:target.size];
        
        // the formula for the May d_1 comes straight from the Steenrod
        // diagonal: d_1 h_{i,j} = sum_{k=1}^{i-1} h_{k,i-k+j} h_{i-k,j}
        for (int k = 1; k <= i-1; k++) {
            EXTMayTag *tagLeft = [EXTMayTag tagWithI:k J:(i-k+j)],
                      *tagRight = [EXTMayTag tagWithI:(i-k) J:j];
            int leftIndex = [sseq.names indexOfObject:tagLeft],
                rightIndex = [sseq.names indexOfObject:tagRight];
            EXTMatrix *product = [sseq productWithLeft:sseq.locations[leftIndex] right:sseq.locations[rightIndex]];
            partial.differential = [EXTMatrix sum:partial.differential with:product];
        }
        
        [diff.partialDefinitions addObject:partial];
        [sseq addDifferential:diff];
    }
    
    // propagate the d1 differentials with Leibniz's rule
    [sseq propagateLeibniz:sseq.locations page:1];
    
    [sseq computeGroupsForPage:0];
    [sseq computeGroupsForPage:1];
    [sseq computeGroupsForPage:2];
    
    // then propagate with nakamura's lemma until exhausted
    
    return sseq;
}

@end
