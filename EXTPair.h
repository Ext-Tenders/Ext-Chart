//
//  EXTPair.h
//  Ext Chart
//
//  Created by Spencer Liang on 7/27/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTLocation.h"

@interface EXTPair : NSObject <EXTLocation> {
	int a, b;
}
@property(readonly, assign) int a;
@property(readonly, assign) int b;
-(id) initWithA:(int)aa B:(int)bb;
+(id) pairWithA:(int)aa B:(int)bb;

-(EXTIntPoint) makePoint;
-(NSString *) description;
+(EXTPair*) addLocation:(EXTPair*)a to:(EXTPair*)b;
+(EXTPair*) identityLocation;
+(EXTPair*) negate:(EXTPair*)loc;
+(EXTPair*) scale:(EXTPair*)loc by:(int)scale;
+(EXTPair*) followDiffl:(EXTPair*)a page:(int)page;
+(EXTPair*) reverseDiffl:(EXTPair*)b page:(int)page;
-(BOOL) isEqual:(EXTPair*)other;

@end
