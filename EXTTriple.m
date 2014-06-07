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




@implementation EXTTripleToPoint

@synthesize internalToUser, userToScreen;

-(id)init {
    if (!(self = [super init]))
        return nil;
    
    self.internalToUser = [EXTMatrix identity:3];
    self.userToScreen = [EXTMatrix matrixWidth:3 height:2];
    
    self.userToScreen.presentation[0][0] = @(-1);
    self.userToScreen.presentation[0][1] = @1;
    self.userToScreen.presentation[1][0] = @1;
    
    return self;
}

-(EXTTriple*) convertFromInternalToUser:(EXTTriple*)loc {
    EXTMatrix *matFromPair = [EXTMatrix matrixWidth:1 height:3];
    matFromPair.presentation[0][0] = @(loc.a);
    matFromPair.presentation[0][1] = @(loc.b);
    matFromPair.presentation[0][2] = @(loc.c);
    
    EXTMatrix *converted = [EXTMatrix newMultiply:internalToUser by:matFromPair];
    return [EXTTriple tripleWithA:[converted.presentation[0][0] intValue]
                                B:[converted.presentation[0][1] intValue]
                                C:[converted.presentation[0][2] intValue]];
}

-(EXTTriple*) convertFromUserToInternal:(EXTTriple*)loc {
    // TODO: we'd like to just use the -invert method here, but at the moment it
    // looks like it uses -columnReduce, which is fixed to mod 2 arithmetic.
    
    NSArray *m = internalToUser.presentation;
    
    NSInteger det = [m[0][0] intValue] *
                    ([m[1][1] intValue] * [m[2][2] intValue] -
                     [m[1][2] intValue] * [m[2][1] intValue]) -
                    [m[1][0] intValue] *
                    ([m[0][1] intValue] * [m[2][2] intValue] -
                     [m[2][1] intValue] * [m[0][2] intValue]) +
                    [m[2][0] intValue] *
                    ([m[0][1] intValue] * [m[1][2] intValue] -
                     [m[1][1] intValue] * [m[0][2] intValue]);
    
    // XXX: surely this can be handled more gracefully. in any case, det should
    // be a multiplicative unit.
    assert(det == 1 || det == -1);
    
    // TODO: this actually write out the formula for an inverse manually.
    // this is terrible. :( it will be a wonder if i get it completely right.
    EXTMatrix *userToInternal = [EXTMatrix matrixWidth:3 height:3];
    userToInternal.presentation[0][0] =
        @([m[1][1] intValue]*[m[2][2] intValue] -
          [m[2][0] intValue]*[m[1][2] intValue]);
    userToInternal.presentation[0][1] =
        @([m[2][1] intValue]*[m[0][2] intValue] -
          [m[0][1] intValue]*[m[2][2] intValue]);
    userToInternal.presentation[0][2] =
        @([m[0][1] intValue]*[m[1][2] intValue] -
          [m[1][1] intValue]*[m[0][2] intValue]);
    userToInternal.presentation[1][0] =
        @([m[2][0] intValue]*[m[1][2] intValue] -
          [m[1][0] intValue]*[m[2][2] intValue]);
    userToInternal.presentation[1][1] =
        @([m[0][0] intValue]*[m[2][2] intValue] -
          [m[2][0] intValue]*[m[0][2] intValue]);
    userToInternal.presentation[1][2] =
        @([m[1][0] intValue]*[m[0][2] intValue] -
          [m[0][0] intValue]*[m[1][2] intValue]);
    userToInternal.presentation[2][0] =
        @([m[1][0] intValue]*[m[2][1] intValue] -
          [m[2][0] intValue]*[m[1][1] intValue]);
    userToInternal.presentation[2][1] =
        @([m[2][0] intValue]*[m[0][1] intValue] -
          [m[0][0] intValue]*[m[2][1] intValue]);
    userToInternal.presentation[2][2] =
        @([m[0][0] intValue]*[m[1][1] intValue] -
          [m[1][0] intValue]*[m[0][1] intValue]);
    
    userToInternal = [userToInternal scale:(1/det)];
    
    NSArray *result = [userToInternal actOn:@[@(loc.a), @(loc.b), @(loc.c)]];
    
    return [EXTTriple tripleWithA:[result[0] intValue]
                                B:[result[1] intValue]
                                C:[result[2] intValue]];
}

-(EXTIntPoint) gridPoint:(EXTTriple*)loc {
    EXTTriple *userCoordsTriple = [self convertFromInternalToUser:loc];
    
    EXTMatrix *userCoords = [EXTMatrix matrixWidth:1 height:3];
    userCoords.presentation[0][0] = @(userCoordsTriple.a);
    userCoords.presentation[0][1] = @(userCoordsTriple.b);
    userCoords.presentation[0][2] = @(userCoordsTriple.c);
    
    EXTMatrix *screenCoords = [EXTMatrix newMultiply:userToScreen by:userCoords];
    
    return (EXTIntPoint)
    {[screenCoords.presentation[0][0] intValue],
        [screenCoords.presentation[0][1] intValue]};
}

-(EXTIntPoint) followDifflAtGridLocation:(EXTIntPoint)gridLocation
                                    page:(int)page {
    EXTMatrix *composite = [EXTMatrix newMultiply:userToScreen
                                               by:internalToUser];
    
    EXTMatrix *clickCoord = [EXTMatrix matrixWidth:1 height:2];
    clickCoord.presentation[0][0] = @((int)gridLocation.x);
    clickCoord.presentation[0][1] = @((int)gridLocation.y);
    
    NSArray *pair = [EXTMatrix formIntersection:composite with:clickCoord];
    
    EXTTriple *liftedTriple;
    NSArray *lift;
    
    if ([((EXTMatrix*)pair[1]).presentation[0][0] intValue] != 0) {
        lift = ((EXTMatrix*)pair[0]).presentation[0];
        
        liftedTriple = [EXTTriple tripleWithA:[lift[0] intValue]
                                            B:[lift[1] intValue]
                                            C:[lift[2] intValue]];
        if ([((EXTMatrix*)pair[1]).presentation[0][0] intValue] == -1)
            liftedTriple = [EXTTriple scale:liftedTriple by:-1];
    } else {
        lift = ((EXTMatrix*)pair[0]).presentation[1];
        
        liftedTriple = [EXTTriple tripleWithA:[lift[0] intValue]
                                            B:[lift[1] intValue]
                                            C:[lift[2] intValue]];
        if ([((EXTMatrix*)pair[1]).presentation[1][0] intValue] == -1)
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

-(id)initWithCoder:(NSCoder *)aDecoder {
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

-(id)copyWithZone:(NSZone *)zone {
    EXTTripleToPoint *newConvertor = [EXTTripleToPoint init];
    
    newConvertor.internalToUser = [self.internalToUser copy];
    newConvertor.userToScreen = [self.internalToUser copy];
    
    return newConvertor;
}

@end
