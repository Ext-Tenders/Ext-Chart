//
//  EXTTriple.m
//  Ext Chart
//
//  Created by Eric Peterson on 5/29/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTTriple.h"

// TODO: implement the NSCoder and NSCopying protocols.
// TODO: possibly someday we'll want to replace both EXTPair and EXTTriple by
//       some kind of EXTTuple object.  for now, though, this is fine.
@implementation EXTTriple

@synthesize a, b, c;

- (id) initWithA:(int)aa B:(int)bb C:(int)cc {
	if (self = [super init]) {
		a = aa; b = bb; c = cc;
	}
	return self;
}

+ (id) tripleWithA:(int)aa B:(int)bb C:(int)cc {
	EXTTriple* triple = [[EXTTriple alloc] initWithA:aa B:bb C:cc];
	return triple;
}

// more generally, maybe this could be replaced with an arbitrary projection mtx
-(EXTIntPoint) gridPoint {
    return (EXTIntPoint){[self b] - [self a], [self a]};
}

-(NSString*) description {
    return [NSString stringWithFormat:@"(%d %d %d)",
                                                [self a], [self b], [self c]];
}

+(EXTTriple*) addLocation:(EXTTriple *)a to:(EXTTriple *)b {
    return [EXTTriple tripleWithA:(a.a + b.a) B:(a.b + b.b) C:(a.c + b.c)];
}

+(EXTTriple*) identityLocation {
    return [EXTTriple tripleWithA:0 B:0 C:0];
}

+(EXTTriple*) negate:(EXTTriple*)loc {
    return [EXTTriple tripleWithA:(-loc.a) B:(-loc.b) C:(-loc.c)];
}

+(EXTTriple*) scale:(EXTTriple*)loc by:(int)scale {
    return [EXTTriple tripleWithA:(loc.a*scale) B:(loc.b*scale) C:(loc.c*scale)];
}

+(EXTTriple*) followDiffl:(EXTTriple *)a page:(int)page {
    return [EXTTriple tripleWithA:(a.a + 1) B:(a.b) C:(a.c + 1 - page)];
}

+(EXTTriple*) reverseDiffl:(EXTTriple *)a page:(int)page {
    return [EXTTriple tripleWithA:(a.a - 1) B:(a.b) C:(a.c - 1 + page)];
}

+(EXTIntPoint) followDifflAtGridLocation:(EXTIntPoint)gridLocation page:(int)page {
    return (EXTIntPoint){gridLocation.x - 1, gridLocation.y + 1};
}

+(int) calculateDifflPage:(EXTTriple*)start end:(EXTTriple*)end {
    if ((start.b != end.b) || (start.a + 1 != end.a))
        return -1;
    return (start.c - end.c + 1);
}

+(EXTTriple*) convertFromString:(NSString *)input {
    NSInteger a = 0, b = 0, c = 0;
    NSScanner *scanner = [NSScanner scannerWithString:input];
    [scanner scanString:@"(" intoString:nil];
    if (![scanner scanInteger:&a])
        return nil;
    [scanner scanString:@"," intoString:nil];
    if (![scanner scanInteger:&b])
        return nil;
    [scanner scanString:@"," intoString:nil];
    if (![scanner scanInteger:&c])
        return nil;
    
    return [EXTTriple tripleWithA:a B:b C:c];
}

-(EXTTriple*) copyWithZone:(NSZone*)zone {
    return [[EXTTriple allocWithZone:zone] initWithA:self.a B:self.b C:self.c];
}

- (NSUInteger) hash {
	long long key = [self a];
	key += [self b];
	key = (~key) + (key << 18); // key = (key << 18) - key - 1;
    key += [self c];
	key = key ^ (key >> 31);
	key = key * 21; // key = (key + (key << 2)) + (key << 4);
	key = key ^ (key >> 11);
	key = key + (key << 6);
	key = key ^ (key >> 22);
	return (int) key;
}

-(BOOL) isEqual:(id)other {
    if ([other class] != [EXTTriple class])
        return false;
    
    return ((a == ((EXTTriple*)other)->a) &&
            (b == ((EXTTriple*)other)->b) &&
            (c == ((EXTTriple*)other)->c));
}

-(id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        a = [aDecoder decodeIntForKey:@"a"];
        b = [aDecoder decodeIntForKey:@"b"];
        c = [aDecoder decodeIntForKey:@"c"];
    }
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInt:a forKey:@"a"];
    [aCoder encodeInt:b forKey:@"b"];
    [aCoder encodeInt:c forKey:@"c"];
}

@end
