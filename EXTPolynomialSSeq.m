//
//  EXTPolynomialSSeq.m
//  Ext Chart
//
//  Created by Eric Peterson on 7/6/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTPolynomialSSeq.h"
#import "EXTterm.h"

// make the new member arrays write-able, provided we're in-file.
@interface EXTPolynomialSSeq ()
@property(strong) NSMutableArray* names;
@property(strong) NSMutableArray* locations;
@property(strong) NSMutableArray* upperBounds;
@end



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
    
    EXTTerm *unit = [EXTTerm term:[locClass identityLocation] andNames:[NSMutableArray arrayWithObject:@"1"]];
    [ret.terms setObject:unit forKey:unit.location];
    
    return ret;
}

// performs an irreversible upcast
-(EXTSpectralSequence*) unspecialize {
    return nil;
}

/*
 
 EXTTerms should have names which aren't strings but "tags".  each tag should be
 either a list or a dictionary or something of pairs of base class + exponent.
 multiplication should act by iterating through and adding these lists together.
 
 for robustness, a nil entry in a tag should be thought of as zero, so that when
 introducing a new class we don't have to go back and add a bunch of labels to
 the existing tags.
 
 */

-(void) addPolyClass:(NSString*)name location:(EXTLocation*)loc upTo:(int)bound {
    return;
}

-(void) resizePolyClass:(NSString*)name upTo:(int)newBound {
    return;
}

-(EXTMatrix*) productWithLeft:(EXTLocation*)left right:(EXTLocation*)right {
    return nil;
}

-(void) propagateLeibniz:(NSArray *)locations page:(int)page {
    return;
}

@end
