//
//  EXTTriple.h
//  Ext Chart
//
//  Created by Eric Peterson on 5/29/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

@import Foundation;

#import "EXTLocation.h"
#import "EXTMatrix.h"

@interface EXTTriple : NSObject <EXTLocation>

@property(readonly, assign) int a;
@property(readonly, assign) int b;
@property(readonly, assign) int c;

-(instancetype) initWithA:(int)aa B:(int)bb C:(int)cc;
+(instancetype) tripleWithA:(int)aa B:(int)bb C:(int)cc;

-(EXTIntPoint) gridPoint;
-(NSString *) description;
+(EXTTriple*) identityLocation;
+(EXTTriple*) negate:(EXTTriple*)loc;
+(EXTTriple*) scale:(EXTTriple*)loc by:(int)scale;
+(EXTTriple*) addLocation:(EXTTriple*)a to:(EXTTriple*)b;
+(EXTTriple*) followDiffl:(EXTTriple*)a page:(int)page;
+(EXTTriple*) reverseDiffl:(EXTTriple*)b page:(int)page;

@end



@interface EXTTripleToPoint : NSObject <EXTLocationToPoint>

// the internal coordinates are always such that the rth differential has
// signature d_r : E_r^{a, b} --> E_r^{a-1, b+r}, i.e., they follow the Adams
// grading.  these EXTPair vectors designate the 's' and 't' coordinates within
// this internal grading, i.e., they describe the mapping (a, b) |-> (s, t).
//
// this is required to be an integrally invertible linear mapping.
@property (strong) EXTMatrix *internalToUser;

// then, a second projection is performed to produce screen coordinates for
// drawing. these describe the second map in (a, b) |-> (s, t) |-> (x, y).
//
// this map is *NOT* required to be invertible.
@property (strong) EXTMatrix *userToScreen;

-(EXTIntPoint) gridPoint:(EXTTriple*)loc;
// this routine only makes sense when differentials are projected orthogonally
// to the screen layer.  this should always be the case, but we may not bother
// to enforce it explicitly.
-(EXTIntPoint) followDifflAtGridLocation:(EXTIntPoint)gridLocation
                                    page:(int)page;
-(EXTTriple*) convertFromString:(NSString*)input;
-(NSString*) convertToString:(EXTTriple*)loc;

@end
