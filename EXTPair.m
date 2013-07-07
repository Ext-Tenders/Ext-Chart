//
//  EXTPair.m
//  Ext Chart
//
//  Created by Spencer Liang on 7/27/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTPair.h"


@implementation EXTPair
@synthesize a;
@synthesize b;

- (id) initWithA:(int)aa B:(int)bb {
	if (self = [super init]) {
		a = aa;
        b = bb;
	}
	return self;
}

+ (id) pairWithA:(int)aa B:(int)bb {
	EXTPair* pair = [[EXTPair alloc] initWithA:aa B:bb];
	return pair;
}

- (NSPoint) makePoint {
	return NSMakePoint([self a], [self b]);
}

+(EXTPair*) addLocation:(EXTPair *)a to:(EXTPair *)b {
    return [EXTPair pairWithA:(a.a+b.a) B:(a.b+b.b)];
}

+(EXTPair*) identityLocation {
    return [EXTPair pairWithA:0 B:0];
}

+(EXTPair*) negate:(EXTPair*)loc {
    return [EXTPair pairWithA:(-loc.a) B:(-loc.b)];
}

+(EXTPair*) scale:(EXTPair*)loc by:(int)scale {
    return [EXTPair pairWithA:(loc.a*scale) B:(loc.b*scale)];
}

+(EXTPair*) followDiffl:(EXTPair*)a page:(int)page {
    return [EXTPair pairWithA:(a.a-1) B:(a.b+page)];
}

+(EXTPair*) reverseDiffl:(EXTPair*)b page:(int)page {
    return [EXTPair pairWithA:(b.a+1) B:(b.b-page)];
}

/// NSCoder, NSCopying routines ///

-(EXTPair*) copyWithZone:(NSZone*)zone {
    return [[EXTPair allocWithZone:zone] initWithA:self.a B:self.b];
}

- (NSUInteger) hash {
	long long key = [self a];
	key += [self b];
	key = (~key) + (key << 18); // key = (key << 18) - key - 1;
	key = key ^ (key >> 31);
	key = key * 21; // key = (key + (key << 2)) + (key << 4);
	key = key ^ (key >> 11);
	key = key + (key << 6);
	key = key ^ (key >> 22);
	return (int) key;
}

-(BOOL) isEqual:(id)other {
    if ([other class] != [EXTPair class])
        return FALSE;
    
	return (([other a] == [self a]) && ([other b] == [self b]));
}

-(NSString *) description {
	return [NSString stringWithFormat: @"(%d %d)", [self a], [self b]];
}

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super init])
	{
		a = [coder decodeIntForKey:@"a"];
		b = [coder decodeIntForKey:@"b"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder*) coder {
	[coder encodeInt:a forKey:@"a"];
	[coder encodeInt:b forKey:@"b"];
}

@end
