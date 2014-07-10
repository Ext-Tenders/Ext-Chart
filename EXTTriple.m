//
//  EXTTriple.m
//  Ext Chart
//
//  Created by Eric Peterson on 5/29/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTTriple.h"


@implementation EXTTriple

@synthesize a, b, c;

- (instancetype) initWithA:(int)aa B:(int)bb C:(int)cc {
	if (self = [super init]) {
		a = aa; b = bb; c = cc;
	}
	return self;
}

+ (instancetype) tripleWithA:(int)aa B:(int)bb C:(int)cc {
	EXTTriple* triple = [[EXTTriple alloc] initWithA:aa B:bb C:cc];
	return triple;
}

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

// XXX: i have no idea if this is right or consistent.
- (int)koszulDegree {
    return self.a;
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

-(instancetype) initWithCoder:(NSCoder *)aDecoder {
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

+(EXTTriple*) linearCombination:(CFArrayRef)coeffs
                  ofLocations:(CFArrayRef)generators {
    int a = 0, b = 0, c = 0;
    
    for (int i = 0; i < CFArrayGetCount(coeffs); i++) {
        EXTTriple *thisGuy = CFArrayGetValueAtIndex(generators, i);
        NSInteger scale = (NSInteger)CFArrayGetValueAtIndex(coeffs, i);
        
        a += scale*thisGuy.a;
        b += scale*thisGuy.b;
        c += scale*thisGuy.c;
    }
    
    return [EXTTriple tripleWithA:a B:b C:c];
}

@end




@implementation EXTTripleToPoint

@synthesize internalToUser, userToScreen;

-(instancetype)init {
    if (!(self = [super init]))
        return nil;
    
    self.internalToUser = [EXTMatrix identity:3];
    self.userToScreen = [EXTMatrix matrixWidth:3 height:2];
    
    int *userToScreenData = userToScreen.presentation.mutableBytes;
    
    userToScreenData[2*0+0] = -1;
    userToScreenData[2*0+1] = 1;
    userToScreenData[2*1+0] = 1;
    
    return self;
}

-(EXTTriple*) convertFromInternalToUser:(EXTTriple*)loc {
    EXTMatrix *matFromPair = [EXTMatrix matrixWidth:1 height:3];
    int *matFromPairData = matFromPair.presentation.mutableBytes;
    matFromPairData[1*0 + 0] = loc.a;
    matFromPairData[1*0 + 1] = loc.b;
    matFromPairData[1*0 + 2] = loc.c;
    
    EXTMatrix *converted = [EXTMatrix newMultiply:internalToUser by:matFromPair];
    int *convertedData = converted.presentation.mutableBytes;
    return [EXTTriple tripleWithA:convertedData[3*0+0]
                                B:convertedData[3*0+1]
                                C:convertedData[3*0+2]];
}

-(EXTTriple*) convertFromUserToInternal:(EXTTriple*)loc {
    EXTMatrix *userToInternal = [internalToUser invert];
    
    assert(userToInternal != nil);
    
    NSArray *result = [userToInternal actOn:@[@(loc.a), @(loc.b), @(loc.c)]];
    
    return [EXTTriple tripleWithA:[result[0] intValue]
                                B:[result[1] intValue]
                                C:[result[2] intValue]];
}

-(EXTIntPoint) gridPoint:(EXTTriple*)loc {
    EXTTriple *userCoordsTriple = [self convertFromInternalToUser:loc];
    NSArray *userCoords = @[@(userCoordsTriple.a),
                            @(userCoordsTriple.b),
                            @(userCoordsTriple.c)];
    
    NSArray *screenCoords = [userToScreen actOn:userCoords];
    
    return (EXTIntPoint){[screenCoords[0] intValue],
                         [screenCoords[1] intValue]};
}

-(EXTIntPoint) followDifflAtGridLocation:(EXTIntPoint)gridLocation
                                    page:(int)page {
    EXTMatrix *composite = [EXTMatrix newMultiply:userToScreen
                                               by:internalToUser];
    
    EXTMatrix *clickCoord = [EXTMatrix matrixWidth:1 height:2];
    int *clickCoordData = clickCoord.presentation.mutableBytes;
    clickCoordData[2*0+0] = (int)gridLocation.x;
    clickCoordData[2*0+1] = (int)gridLocation.y;
    
    NSArray *pair = [EXTMatrix formIntersection:composite with:clickCoord];
    
    EXTTriple *liftedTriple;
    
    int *leftData = ((EXTMatrix*)pair[0]).presentation.mutableBytes,
        *rightData = ((EXTMatrix*)pair[1]).presentation.mutableBytes;
    
    if (rightData[0] != 0) {
        liftedTriple = [EXTTriple tripleWithA:leftData[0]
                                            B:leftData[1]
                                            C:leftData[2]];
        if (rightData[0] == -1)
            liftedTriple = [EXTTriple scale:liftedTriple by:-1];
    } else {
        liftedTriple = [EXTTriple tripleWithA:leftData[3]
                                            B:leftData[4]
                                            C:leftData[5]];
        if (rightData[1] == -1)
            liftedTriple = [EXTTriple scale:liftedTriple by:-1];
    }
    
    return [self gridPoint:[EXTTriple followDiffl:liftedTriple page:page]];
}

-(EXTTriple*) convertFromString:(NSString *)input {
    NSInteger s = 0, t = 0, u = 0;
    NSScanner *scanner = [NSScanner scannerWithString:input];
    [scanner scanString:@"(" intoString:nil];
    if (![scanner scanInteger:&s])
        return nil;
    [scanner scanString:@"," intoString:nil];
    if (![scanner scanInteger:&t])
        return nil;
    [scanner scanString:@"," intoString:nil];
    if (![scanner scanInteger:&u])
        return nil;
    
    return [self convertFromUserToInternal:[EXTTriple tripleWithA:s B:t C:u]];
}

-(NSString*) convertToString:(EXTTriple*)loc {
    EXTTriple *user = [self convertFromInternalToUser:loc];
    
    return [NSString stringWithFormat: @"(%d %d %d)", user.a, user.b, user.c];
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
    EXTTripleToPoint *newConvertor = [EXTTripleToPoint init];
    
    newConvertor.internalToUser = [self.internalToUser copy];
    newConvertor.userToScreen = [self.internalToUser copy];
    
    return newConvertor;
}

@end
