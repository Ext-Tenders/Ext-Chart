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
- (id) initWithA:(int)aa AndB:(int)bb;
+ (id) pairWithA:(int)aa AndB:(int)bb;
- (NSPoint) makePoint;
-(NSString *) description;

@end
