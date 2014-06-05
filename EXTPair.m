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

+(int) calculateDifflPage:(EXTPair*)start end:(EXTPair*)end {
    if ((start.a + 1 != end.a))
        return -1;
    return (end.b - start.b);
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






@implementation EXTPairToPoint

@synthesize firstInternalCoord,
            secondInternalCoord,
            firstScreenCoord,
            secondScreenCoord;

-(id)init {
    if (!(self = [super init]))
        return nil;
    
    self.firstInternalCoord = [EXTPair pairWithA:1 B:0];
    self.secondInternalCoord = [EXTPair pairWithA:0 B:1];
    self.firstScreenCoord = EXTIntPointFromNSPoint(NSMakePoint(1., 0.));
    self.secondScreenCoord = EXTIntPointFromNSPoint(NSMakePoint(0., 1.));
    
    return self;
}

// the standard coordinate system is
- (id)initAdamsGrading {
    self = [self init];
    
    // (a, b) |-> (b, a+b)
    self.firstInternalCoord = [EXTPair pairWithA:0 B:1];
    self.secondInternalCoord = [EXTPair pairWithA:1 B:1];
    
    // (s, t) |-> (t-s, s)
    self.firstScreenCoord = (EXTIntPoint){-1., 1.};
    self.secondScreenCoord = (EXTIntPoint){1., 0.};
    
    return self;
}

- (id)initCohomologicalSerreGrading {
    self = [self init];
    
    // differentials should go d_r: E_r^{s, t} --> E_r^{s+r, t-r+1}.
    self.firstInternalCoord = [EXTPair pairWithA:0 B:(-1)];
    self.secondInternalCoord = [EXTPair pairWithA:1 B:(-1)];
    
    // internal coordinates = visible coordinates.
    // perform a NOP to project to screen.
    self.firstScreenCoord = (EXTIntPoint){1., 0.};
    self.secondScreenCoord = (EXTIntPoint){0., 1.};
    
    return self;
}

- (id)initHomologicalSerreGrading {
    self = [self init];
    
    // differentials should go d_r: E_r^{s, t} --> E_r^{s-r, t+r-1}.
    self.firstInternalCoord = [EXTPair pairWithA:0 B:1];
    self.secondInternalCoord = [EXTPair pairWithA:(-1) B:1];
    
    // internal coordinates = visible coordinates.
    // perform a NOP to project to screen.
    self.firstScreenCoord = (EXTIntPoint){1., 0.};
    self.secondScreenCoord = (EXTIntPoint){0., 1.};
    
    return self;
}

-(EXTPair*) convertFromInternalToUser:(EXTPair*)loc {
    return [EXTPair
      pairWithA:(loc.a * firstInternalCoord.a + loc.b * secondInternalCoord.a)
              B:(loc.a * firstInternalCoord.b + loc.b * secondInternalCoord.b)];
}

-(EXTPair*) convertFromUserToInternal:(EXTPair*)loc {
    NSInteger det = firstInternalCoord.a * secondInternalCoord.b -
                    firstInternalCoord.b * secondInternalCoord.a;
    
    // XXX: surely this can be handled more gracefully. in any case, det should
    // be a multiplicative unit.
    assert(det == 1 || det == -1);
    
    int a = (loc.a*secondInternalCoord.b - loc.b*secondInternalCoord.a)/det,
        b = (loc.a*(-firstInternalCoord.b) + loc.b*firstInternalCoord.a)/det;
    
    return [EXTPair pairWithA:a B:b];
}

-(EXTIntPoint) gridPoint:(EXTPair*)loc {
    EXTPair *userCoords = [self convertFromInternalToUser:loc];
    return (EXTIntPoint)
       {userCoords.a * firstScreenCoord.x + userCoords.b * secondScreenCoord.x,
        userCoords.a * firstScreenCoord.y + userCoords.b * secondScreenCoord.y};
}

-(EXTIntPoint) followDifflAtGridLocation:(EXTIntPoint)gridLocation
                                    page:(int)page {
    EXTMatrix *userToScreen = [EXTMatrix matrixWidth:2 height:2],
              *internalToUser = [EXTMatrix matrixWidth:2 height:2];
    
    userToScreen.presentation[0][0] = @(firstScreenCoord.x);
    userToScreen.presentation[0][1] = @(firstScreenCoord.y);
    userToScreen.presentation[1][0] = @(secondScreenCoord.x);
    userToScreen.presentation[1][1] = @(secondScreenCoord.y);
    
    internalToUser.presentation[0][0] = @(firstInternalCoord.a);
    internalToUser.presentation[0][1] = @(firstInternalCoord.b);
    internalToUser.presentation[1][0] = @(secondInternalCoord.a);
    internalToUser.presentation[1][1] = @(secondInternalCoord.b);
    
    EXTMatrix *composite = [EXTMatrix newMultiply:userToScreen
                                               by:internalToUser];
    
    EXTMatrix *clickCoord = [EXTMatrix matrixWidth:1 height:2];
    clickCoord.presentation[0][0] = @((int)gridLocation.x);
    clickCoord.presentation[0][1] = @((int)gridLocation.y);
    
    NSArray *pair = [EXTMatrix formIntersection:composite with:clickCoord];
    
    NSArray *lift = ((EXTMatrix*)pair[0]).presentation[0];
    
    EXTPair *liftedPair = [EXTPair pairWithA:[lift[0] intValue] B:[lift[1] intValue]];
    
    return [self gridPoint:[EXTPair followDiffl:liftedPair page:page]];
}

-(EXTPair*) convertFromString:(NSString*)input {
    NSInteger s = 0, t = 0;
    NSScanner *scanner = [NSScanner scannerWithString:input];
    [scanner scanString:@"(" intoString:nil];
    if (![scanner scanInteger:&s])
        return nil;
    [scanner scanString:@"," intoString:nil];
    if (![scanner scanInteger:&t])
        return nil;
    
    return [self convertFromUserToInternal:[EXTPair pairWithA:s B:t]];
}

-(NSString*) convertToString:(EXTPair*)loc {
    EXTPair *user = [self convertFromInternalToUser:loc];
    
    return [NSString stringWithFormat: @"(%d %d)", user.a, user.b];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        firstInternalCoord =
            [aDecoder decodeObjectForKey:@"firstInternalCoord"];
        secondInternalCoord =
            [aDecoder decodeObjectForKey:@"secondInternalCoord"];
        firstScreenCoord = EXTIntPointFromNSPoint(
            [aDecoder decodePointForKey:@"firstScreenCoord"]);
        secondScreenCoord = EXTIntPointFromNSPoint(
            [aDecoder decodePointForKey:@"secondScreenCoord"]);
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:firstInternalCoord forKey:@"firstInternalCoord"];
    [aCoder encodeObject:secondInternalCoord forKey:@"secondInternalCoord"];
    [aCoder encodePoint:NSPointFromEXTIntPoint(firstScreenCoord)
                 forKey:@"firstScreenCoord"];
    [aCoder encodePoint:NSPointFromEXTIntPoint(secondScreenCoord)
                 forKey:@"secondScreenCoord"];
    
    return;
}

-(id)copyWithZone:(NSZone *)zone {
    EXTPairToPoint *newConvertor = [EXTPairToPoint init];
    
    newConvertor.firstInternalCoord = self.firstInternalCoord;
    newConvertor.secondInternalCoord = self.secondInternalCoord;
    newConvertor.firstScreenCoord = self.firstScreenCoord;
    newConvertor.secondScreenCoord = self.secondScreenCoord;
    
    return newConvertor;
}

@end
