//
//  EXTPair.h
//  Ext Chart
//
//  Created by Spencer Liang on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTLocation.h"

@interface EXTPair : NSObject <NSCopying, NSCoding, EXTLocation> {
	int a, b;
}
@property int a;
@property int b;
-(id) initWithA:(int)aa B:(int)bb;
+(id) pairWithA:(int)aa B:(int)bb;

-(NSPoint) makePoint;
-(NSString *) description;
+(EXTPair*) addLocation:(EXTPair*)a to:(EXTPair*)b;
+(EXTPair*) followDiffl:(EXTPair*)a page:(int)page;
+(EXTPair*) reverseDiffl:(EXTPair*)b page:(int)page;

@end
