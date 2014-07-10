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

- (instancetype) initWithA:(int)aa B:(int)bb {
	if (self = [super init]) {
		a = aa;
        b = bb;
	}
	return self;
}

+ (instancetype) pairWithA:(int)aa B:(int)bb {
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

-(int)koszulDegree {
    return self.b;
}

+(EXTPair*) linearCombination:(CFArrayRef)coeffs
                  ofLocations:(CFArrayRef)generators {
    int a = 0, b = 0;
    
    for (int i = 0; i < CFArrayGetCount(coeffs); i++) {
        EXTPair *thisGuy = CFArrayGetValueAtIndex(generators, i);
        NSInteger scale = (NSInteger)CFArrayGetValueAtIndex(coeffs, i);
        
        a += scale*thisGuy.a;
        b += scale*thisGuy.b;
    }
    
    return [EXTPair pairWithA:a B:b];
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

- (instancetype) initWithCoder: (NSCoder*) coder {
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

@synthesize internalToUser, userToScreen;

-(instancetype)init {
    if (!(self = [super init]))
        return nil;
    
    self.internalToUser = [EXTMatrix identity:2];
    self.userToScreen = [EXTMatrix identity:2];
    
    return self;
}

// the standard Z^2 coordinate system is graded so that setting both projection
// matrices to the identity produces the Adams grading on display. however, this
// is not what topologists are used to thinking of as the 'internal' grading to
// an Adams spectral sequence: they want the axes to be labeled (t-s, s) for
// internal coordinates (s, t). these matrices set up this yoga.
- (instancetype)initAdamsGrading {
    self = [self init];
    
    // (a, b) |-> (b, a+b)
    int *internalToUserData = internalToUser.presentation.mutableBytes;
    internalToUserData[0*2 + 0] = 0;
    internalToUserData[0*2 + 1] = 1;
    internalToUserData[1*2 + 0] = 1;
    internalToUserData[1*2 + 1] = 1;
    
    // (s, t) |-> (t-s, s)
    int *userToScreenData = userToScreen.presentation.mutableBytes;
    userToScreenData[0*2 + 0] = -1;
    userToScreenData[0*2 + 1] = 1;
    userToScreenData[1*2 + 0] = 1;
    userToScreenData[1*2 + 1] = 0;
    
    return self;
}

- (instancetype)initCohomologicalSerreGrading {
    self = [self init];
    
    // differentials should go d_r: E_r^{s, t} --> E_r^{s+r, t-r+1}.
    int *internalToUserData = internalToUser.presentation.mutableBytes;
    internalToUserData[2*0 + 0] = 0;
    internalToUserData[2*0 + 1] = -1;
    internalToUserData[2*1 + 0] = 1;
    internalToUserData[2*1 + 1] = -1;
    
    // internal coordinates = visible coordinates.
    // perform a NOP to project to screen.
    userToScreen = [EXTMatrix identity:2];
    
    return self;
}

- (instancetype)initHomologicalSerreGrading {
    self = [self init];
    
    // differentials should go d_r: E_r^{s, t} --> E_r^{s-r, t+r-1}.
    int *internalToUserData = internalToUser.presentation.mutableBytes;
    internalToUserData[2*0 + 0] = 0;
    internalToUserData[2*0 + 1] = 1;
    internalToUserData[2*1 + 0] = -1;
    internalToUserData[2*1 + 1] = 1;
    
    // internal coordinates = visible coordinates.
    // perform a NOP to project to screen.
    userToScreen = [EXTMatrix identity:2];
    
    return self;
}

-(EXTPair*) convertFromInternalToUser:(EXTPair*)loc {
    NSArray *converted = [internalToUser actOn:@[@(loc.a), @(loc.b)]];
    return [EXTPair pairWithA:[converted[0] intValue]
                            B:[converted[1] intValue]];
}

-(EXTPair*) convertFromUserToInternal:(EXTPair*)loc {
    // TODO: we'd like to just use the -invert method here, but at the moment it
    // looks like it uses -columnReduce, which is fixed to mod 2 arithmetic.
    
    int *internalToUserData = internalToUser.presentation.mutableBytes;
    
    NSInteger det = (internalToUserData[2*0 + 0] *
                     internalToUserData[2*1 + 1]) -
                    (internalToUserData[2*0 + 1] *
                     internalToUserData[2*1 + 0]);
    
    // XXX: surely this can be handled more gracefully. in any case, det should
    // be a multiplicative unit.
    assert(det == 1 || det == -1);
    
    int a = (loc.a*internalToUserData[2*1+1] -
             loc.b*internalToUserData[2*1+0]) / det,
        b = (loc.a*internalToUserData[2*0+1]*(-1) +
             loc.b*internalToUserData[2*0+0]) / det;
    
    return [EXTPair pairWithA:a B:b];
}

-(EXTIntPoint) gridPoint:(EXTPair*)loc {
    EXTPair *userCoordsPair = [self convertFromInternalToUser:loc];
    
    NSArray *result = [userToScreen actOn:@[@(userCoordsPair.a),
                                            @(userCoordsPair.b)]];
    return (EXTIntPoint){[result[0] intValue], [result[1] intValue]};
}

-(EXTIntPoint) followDifflAtGridLocation:(EXTIntPoint)gridLocation
                                    page:(int)page {
    EXTMatrix *composite = [EXTMatrix newMultiply:userToScreen
                                               by:internalToUser];
    
    EXTMatrix *clickCoord = [EXTMatrix matrixWidth:1 height:2];
    int *clickCoordData = clickCoord.presentation.mutableBytes;
    clickCoordData[0] = (int)gridLocation.x;
    clickCoordData[1] = (int)gridLocation.y;
    
    NSArray *pair = [EXTMatrix formIntersection:composite with:clickCoord];
    
    int *liftData = ((EXTMatrix*)pair[0]).presentation.mutableBytes;
    NSArray *lift = @[@(liftData[0]), @(liftData[1])];
    
    EXTPair *liftedPair = [EXTPair pairWithA:[lift[0] intValue] B:[lift[1] intValue]];
    
    int *scaleData = ((EXTMatrix*)pair[1]).presentation.mutableBytes;
    if (*scaleData == -1) {
        liftedPair = [EXTPair scale:liftedPair by:-1];
    }
    
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

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        internalToUser = [aDecoder decodeObjectForKey:@"internalToUser"];
        userToScreen = [aDecoder decodeObjectForKey:@"userToScreen"];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:internalToUser forKey:@"internalToUser"];
    [aCoder encodeObject:userToScreen forKey:@"userToScreen"];
    
    return;
}

-(instancetype)copyWithZone:(NSZone *)zone {
    EXTPairToPoint *newConvertor = [EXTPairToPoint init];
    
    newConvertor.internalToUser = [self.internalToUser copy];
    newConvertor.userToScreen = [self.internalToUser copy];
    
    return newConvertor;
}

@end
