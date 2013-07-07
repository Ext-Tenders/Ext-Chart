//
//  EXTLocation.h
//  Ext Chart
//
//  Created by Eric Peterson on 5/29/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
+(EXTLocation*) scale:(EXTLocation*)loc by:(int)scale {
    if (scale == 0)
        return [EXTLocation identityLocation];
    if (scale < 0)
        return [EXTLocation scale:[EXTLocation negate:loc] by:(-scale)];
    
    return [EXTLocation addLocation:loc to:[EXTLocation scale:loc by:(scale-1)]];
}
*/

@protocol EXTLocation <NSObject, NSCopying, NSCoding>

// these translate the EXTLocation data into other (potentially lossy) formats
-(NSPoint) makePoint;
-(NSString *) description;

// these say that EXTLocation forms a Z-module
+(NSObject<EXTLocation>*) identityLocation;
+(NSObject<EXTLocation>*) addLocation:(NSObject<EXTLocation>*)a to:(NSObject<EXTLocation>*)b;
+(NSObject<EXTLocation>*) negate:(NSObject<EXTLocation>*)loc;
+(NSObject<EXTLocation>*) scale:(NSObject<EXTLocation>*)loc by:(int)scale;

// these record the affine translation by a differential
+(NSObject<EXTLocation>*) followDiffl:(NSObject<EXTLocation>*)a page:(int)page;
+(NSObject<EXTLocation>*) reverseDiffl:(NSObject<EXTLocation>*)b page:(int)page;

// these make it possible to use EXTLocation as a dictionary key.
-(BOOL) isEqual:(NSObject<EXTLocation>*)a;
-(NSUInteger) hash;

@end

typedef NSObject<EXTLocation> EXTLocation;
