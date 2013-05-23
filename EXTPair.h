//
//  EXTPair.h
//  Ext Chart
//
//  Created by Spencer Liang on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EXTPair : NSObject <NSCopying, NSCoding> {
	int a, b;
}
@property int a;
@property int b;
- (id) initWithA:(int)aa B:(int)bb;
+ (id) pairWithA:(int)aa B:(int)bb;
- (NSPoint) makePoint;
-(NSString *) description;
+(EXTPair*) addPairs:(EXTPair*)a to:(EXTPair*)b;
+(EXTPair*) followDiffl:(EXTPair*)a page:(int)page;
+(EXTPair*) reverseDiffl:(EXTPair*)b page:(int)page;

@end
