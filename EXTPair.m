//
//  EXTPair.m
//  Ext Chart
//
//  Created by Spencer Liang on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EXTPair.h"


@implementation EXTPair
@synthesize a;
@synthesize b;

- (id) initWithA:(int)aa B:(int)bb {
	if (self = [super init]) {
		[self setA:aa];
		[self setB:bb];
	}
	return self;
}

+ (id) pairWithA:(int)aa B:(int)bb {
	EXTPair* pair = [[EXTPair alloc]initWithA:aa B:bb];
	return [pair autorelease];
}

- (NSPoint) makePoint {
	return NSMakePoint([self a], [self b]);
}

- (id) copyWithZone:(NSZone*) zone {
	EXTPair* copy = [[EXTPair alloc] init];
	[copy setA:[self a]];
	[copy setB:[self b]];
	return copy;
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

- (BOOL) isEqual:(id) other{
	return [other a] == [self a] && [other b] == [self b];
}

-(NSString *) description {
	return [NSString stringWithFormat: @"(%d %d)", [self a], [self b]];
}

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super init])
	{
		[self setA:[coder decodeIntForKey:@"a"]];
		[self setB:[coder decodeIntForKey:@"b"]];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder*) coder {
	[coder encodeInt:a forKey:@"a"];
	[coder encodeInt:b forKey:@"b"];
}

@end
