//
//  EXTPolynomialSSeq.m
//  Ext Chart
//
//  Created by Eric Peterson on 7/6/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTPolynomialSSeq.h"
#import "EXTterm.h"


// EXTTerms should have names which aren't strings but "tags".  each tag should
// be either a dictionary of pairs of base class + exponent.  multiplication
// should act by iterating through and adding these lists together.
//
// for robustness, a nil entry in a tag should be thought of as zero, so that
// when introducing a new class we don't have to go back and add a bunch of
// labels to the existing tags.
@interface EXTPolynomialTag : NSObject

@property(strong) NSMutableDictionary *tags;

-(NSString*) description;
+(EXTPolynomialTag*) sum:(EXTPolynomialTag*)left with:(EXTPolynomialTag*)right;
-(BOOL) isEqual:(id)object;

@end

@implementation EXTPolynomialTag

@synthesize tags;

// sends the tag dictionary [[x, 1], [y, 2]] to the string "x^1 y^2"
-(NSString*) description {
    NSString *ret = [NSMutableString string];
    
    for (NSString *key in tags.keyEnumerator) {
        ret = [ret stringByAppendingFormat:@" (%@)^{%@}", key.description, [tags objectForKey:key]];
    }
    
    return ret;
}

+(EXTPolynomialTag*) sum:(EXTPolynomialTag*)left with:(EXTPolynomialTag*)right {
    EXTPolynomialTag *ret = [left copy];
    
    for (NSString *key in right.tags.keyEnumerator) {
        id leftValue = [left.tags objectForKey:key],
            rightValue = [right.tags objectForKey:key];
        if (!leftValue)
            [ret.tags setObject:rightValue forKey:key];
        else
            [ret.tags setObject:@([rightValue intValue] + [leftValue intValue]) forKey:key];
    }
    
    return nil;
}

-(BOOL) isEqual:(id)object {
    if ([object class] != [EXTPolynomialTag class])
        return FALSE;
    
    EXTPolynomialTag *target = (EXTPolynomialTag*)object;
    
    for (NSString *key in target.tags.keyEnumerator) {
        int value = [[target.tags objectForKey:key] intValue];
        if (value == 0)
            continue;
        NSNumber *selfValue = [tags objectForKey:key];
        if (!selfValue)
            return FALSE;
        if ([selfValue intValue] != value)
            return FALSE;
    }
    
    for (NSString *key in tags.keyEnumerator) {
        int value = [[tags objectForKey:key] intValue];
        if (value == 0)
            continue;
        NSNumber *targetValue = [target.tags objectForKey:key];
        if (!targetValue)
            return FALSE;
        if ([targetValue intValue] != value)
            return FALSE;
    }
    
    return TRUE;
}

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

-(void) addPolyClass:(NSString*)name location:(EXTLocation*)loc upTo:(int)bound {
    // update the navigation members
    [names addObject:name];
    [locations addObject:loc];
    [upperBounds addObject:@0];
    
    [self resizePolyClass:name upTo:bound];
    
    return;
}

-(void) resizePolyClass:(NSString*)name upTo:(int)newBound {
    int index = [names indexOfObject:name];
    
    // set up the array of counters
    EXTPolynomialTag *tag = [EXTPolynomialTag new];
    tag.tags = [NSMutableDictionary dictionaryWithCapacity:names.count];
    for (int i = 0; i < names.count; i++)
        [tag.tags setObject:@0 forKey:names[i]];
    [tag.tags setObject:upperBounds[index] forKey:names[index]];
    
    while (true) {
        // increment the counter
        for (int i = 0; i < names.count; i++) {
            int value = [[tag.tags objectForKey:names[i]] intValue];
            
            // there are two kinds of roll-over
            if ((i == index) && (value + 1 == newBound)) {
                [tag.tags setObject:upperBounds[index] forKey:names[index]];
                continue;
            } else if ((i != index) && (value + 1 == [upperBounds[i] intValue])) {
                [tag.tags setObject:@0 forKey:names[index]];
                continue;
            }
            
            [tag.tags setObject:@(value+1) forKey:names[i]];
            break;
        }
        
        // search for a term in the resulting location
        EXTLocation *workingLoc = [[self indexClass] identityLocation];
        for (int i = 0; i < names.count; i++)
            workingLoc = [[self indexClass] addLocation:workingLoc to:[[self indexClass] scale:locations[i] by:[[tag.tags objectForKey:names[i]] intValue]]];
        EXTTerm *term = [self findTerm:workingLoc];
        
        // if it doesn't exist, create it
        if (!term) {
            term = [EXTTerm term:workingLoc andNames:[NSMutableArray array]];
            [self.terms setObject:term forKey:workingLoc];
        }
        
        // now add the new tag to its names array
        [term.names addObject:[tag copy]];
    }
    
    // store newBound as the new bound
    upperBounds[index] = @(newBound);
    
    return;
}

// builds the multiplication matrix for a pair of EXTLocations
-(EXTMatrix*) productWithLeft:(EXTLocation*)leftLoc right:(EXTLocation*)rightLoc {
    EXTTerm *left = [self findTerm:leftLoc], *right = [self findTerm:rightLoc],
    *target = [self findTerm:[[leftLoc class] addLocation:leftLoc to:rightLoc]];
    
    EXTMatrix *ret = [EXTMatrix matrixWidth:(left.size*right.size) height:target.size];
    
    for (int i = 0; i < left.size; i++)
    for (int j = 0; j < right.size; j++) {
        EXTPolynomialTag *sumTag = [EXTPolynomialTag sum:left.names[i] with:right.names[j]];
        int index = [target.names indexOfObject:sumTag];
        NSMutableArray *retcol = ret.presentation[i*right.size+j];
        retcol[index] = @1;
    }
    
    return ret;
}

-(void) propagateLeibniz:(NSArray *)locations page:(int)page {
    return;
}

@end
