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
    
    return [EXTLocation addLocation:loc
                                 to:[EXTLocation scale:loc
                                 by:(scale-1)]];
}
*/

enum EXTLocationKinds {
    EXTPair_KIND = 0,
    EXTTriple_KIND = 1
};

@protocol EXTLocation <NSObject, NSCopying, NSCoding>

// translates the EXTLocation data into a (potentially lossy) string
-(NSString *) description;

// these say that EXTLocation forms a Z-module
//
// TODO: are there ever situations where it is more reasonable to consider an
// EXTLocation as being a torsor for some abelian group?
+(NSObject<EXTLocation>*) identityLocation;
+(NSObject<EXTLocation>*) addLocation:(NSObject<EXTLocation>*)a
                                   to:(NSObject<EXTLocation>*)b;
+(NSObject<EXTLocation>*) negate:(NSObject<EXTLocation>*)loc;
+(NSObject<EXTLocation>*) scale:(NSObject<EXTLocation>*)loc
                             by:(int)scale;
+(NSObject<EXTLocation>*) linearCombination:(CFArrayRef)coeffs
                                ofLocations:(CFArrayRef)generators;

// for use in e.g. sign rules, for commuting differentials in the leibniz rule
-(int) koszulDegree;

// these record the affine translation by a differential
+(NSObject<EXTLocation>*) followDiffl:(NSObject<EXTLocation>*)a
                                 page:(int)page;
+(NSObject<EXTLocation>*) reverseDiffl:(NSObject<EXTLocation>*)b
                                  page:(int)page;
+(int) calculateDifflPage:(NSObject<EXTLocation>*)start
                      end:(NSObject<EXTLocation>*)end;

// these make it possible to use EXTLocation as a dictionary key.
-(BOOL) isEqual:(NSObject<EXTLocation>*)a;
-(NSUInteger) hash;

@end

// type utility so that we can pretend to refer to a generic 'EXTLocation' class
typedef NSObject<EXTLocation> EXTLocation;


/* --------------------------------------------------------------------------
   -------------------------------------------------------------------------- */

// each class implementing EXTLocation should hold an accompanying class
// implementing EXTLocationToPoint, which translates the arithmetic of the
// underlying EXTLocation into something the UI can use to draw the sseq.
//
// a given sseq will hold on to ONE instance of ONE of the classes and use it to
// compute all of the relevant translations.
@protocol EXTLocationToPoint <NSObject, NSCopying, NSCoding>

-(EXTIntPoint) gridPoint:(EXTLocation*)loc;
-(EXTIntPoint) followDifflAtGridLocation:(EXTIntPoint)gridLocation
                                    page:(int)page;
-(EXTLocation*) convertFromString:(NSString*)input;
-(NSString*) convertToString:(EXTLocation*)loc;

@end

typedef NSObject<EXTLocationToPoint> EXTLocationToPoint;
