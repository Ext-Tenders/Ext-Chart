//
//  EXTTriple.m
//  Ext Chart
//
//  Created by Eric Peterson on 5/29/13.
//  Copyright (c) 2013 HLProducts. All rights reserved.
//

#import "EXTTriple.h"

// TODO: implement the NSCoder and NSCopying protocols.
// TODO: possibly someday we'll want to replace both EXTPair and EXTTriple by
//       some kind of EXTTuple object.  for now, though, this is fine.
@implementation EXTTriple

@synthesize a, b, c;

- (id) initWithA:(int)aa B:(int)bb C:(int)cc {
	if (self = [super init]) {
		[self setA:aa];
		[self setB:bb];
        [self setC:cc];
	}
	return self;
}

+ (id) tripleWithA:(int)aa B:(int)bb C:(int)cc {
	EXTTriple* triple = [[EXTTriple alloc] initWithA:aa B:bb C:cc];
	return triple;
}

// more generally, maybe this could be replaced with an arbitrary projection mtx
-(NSPoint) makePoint {
    return NSMakePoint([self a], [self b]);
}

-(NSString*) description {
    return [NSString stringWithFormat:@"(%d %d %d)",
                                                [self a], [self b], [self c]];
}

+(EXTTriple*) addLocation:(EXTTriple *)a to:(EXTTriple *)b {
    return [EXTTriple tripleWithA:(a.a + b.a) B:(a.b + b.b) C:(a.c + b.c)];
}

+(EXTTriple*) followDiffl:(EXTTriple *)a page:(int)page {
    return [EXTTriple tripleWithA:(a.a - 1) B:(a.b + 1) C:(a.c - page)];
}

+(EXTTriple*) reverseDiffl:(EXTTriple *)a page:(int)page {
    return [EXTTriple tripleWithA:(a.a + 1) B:(a.b - 1) C:(a.c + page)];
}

-(EXTTriple*) copyWithZone:(NSZone*)zone {
    return [EXTTriple tripleWithA:self.a B:self.b C:self.c];
}

@end
