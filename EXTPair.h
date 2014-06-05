//
//  EXTPair.h
//  Ext Chart
//
//  Created by Spencer Liang on 7/27/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTLocation.h"
#import "EXTMatrix.h"

@interface EXTPair : NSObject <EXTLocation> {
	int a, b;
}
@property(readonly, assign) int a;
@property(readonly, assign) int b;
-(id) initWithA:(int)aa B:(int)bb;
+(id) pairWithA:(int)aa B:(int)bb;

+(EXTPair*) addLocation:(EXTPair*)a to:(EXTPair*)b;
+(EXTPair*) identityLocation;
+(EXTPair*) negate:(EXTPair*)loc;
+(EXTPair*) scale:(EXTPair*)loc by:(int)scale;
+(EXTPair*) followDiffl:(EXTPair*)a page:(int)page;
+(EXTPair*) reverseDiffl:(EXTPair*)b page:(int)page;
-(BOOL) isEqual:(EXTPair*)other;

@end



@interface EXTPairToPoint : NSObject <EXTLocationToPoint>

// the internal coordinates are always such that the rth differential has
// signature d_r : E_r^{a, b} --> E_r^{a-1, b+r}, i.e., they follow the Adams
// grading.  these EXTPair vectors designate the 's' and 't' coordinates within
// this internal grading, i.e., they describe the mapping (a, b) |-> (s, t).
//
// this is required to be an integrally invertible linear mapping.
@property (strong) EXTPair* firstInternalCoord;
@property (strong) EXTPair* secondInternalCoord;

// then, a second projection is performed to produce screen coordinates for
// drawing. these describe the second map in (a, b) |-> (s, t) |-> (x, y).
//
// this map is *NOT* required to be invertible.
@property (assign) EXTIntPoint firstScreenCoord;
@property (assign) EXTIntPoint secondScreenCoord;

-(id) initAdamsGrading;
-(id) initHomologicalSerreGrading;
-(id) initCohomologicalSerreGrading;

-(EXTIntPoint) gridPoint:(EXTPair*)loc;
// this routine only makes sense when differentials are projected orthogonally
// to the screen layer.  this should always be the case, but we may not bother
// to enforce it explicitly.
-(EXTIntPoint) followDifflAtGridLocation:(EXTIntPoint)gridLocation
                                    page:(int)page;
-(EXTPair*) convertFromString:(NSString*)input;
-(NSString*) convertToString:(EXTPair*)loc;

@end
