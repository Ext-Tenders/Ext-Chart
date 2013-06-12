//
//  EXTLocation.h
//  Ext Chart
//
//  Created by Eric Peterson on 5/29/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EXTLocation <NSObject, NSCopying, NSCoding>

-(NSPoint) makePoint;
-(NSString *) description;
+(NSObject<EXTLocation>*) addLocation:(NSObject<EXTLocation>*)a to:(NSObject<EXTLocation>*)b;
+(NSObject<EXTLocation>*) negate:(NSObject<EXTLocation>*)loc;
+(NSObject<EXTLocation>*) scale:(NSObject<EXTLocation>*)loc by:(int)scale;
+(NSObject<EXTLocation>*) identityLocation;
+(NSObject<EXTLocation>*) followDiffl:(NSObject<EXTLocation>*)a page:(int)page;
+(NSObject<EXTLocation>*) reverseDiffl:(NSObject<EXTLocation>*)b page:(int)page;
-(BOOL) isEqual:(NSObject<EXTLocation>*)a;

@end

typedef NSObject<EXTLocation> EXTLocation;
