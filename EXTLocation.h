//
//  EXTLocation.h
//  Ext Chart
//
//  Created by Eric Peterson on 5/29/13.
//  Copyright (c) 2013 HLProducts. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EXTLocation <NSObject>

-(NSPoint) makePoint;
-(NSString *) description;
+(NSObject<EXTLocation>*) addLocation:(NSObject<EXTLocation>*)a to:(NSObject<EXTLocation>*)b;
+(NSObject<EXTLocation>*) followDiffl:(NSObject<EXTLocation>*)a page:(int)page;
+(NSObject<EXTLocation>*) reverseDiffl:(NSObject<EXTLocation>*)b page:(int)page;

@end

typedef NSObject<EXTLocation> EXTLocation;
