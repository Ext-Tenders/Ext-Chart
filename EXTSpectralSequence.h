//
//  EXTSpectralSequence.h
//  Ext Chart
//
//  Created by Eric Peterson on 5/31/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EXTLocation.h"
#import "EXTZeroRange.h"
// i guess objective C isn't particularly good at circular dependence
//#import "EXTTerm.h"
//#import "EXTDifferential.h"

@class EXTMultiplicationTables;
@class EXTTerm, EXTDifferential;

@interface EXTSpectralSequence : NSObject <NSCoding>

@property(nonatomic, strong) NSMutableDictionary *terms;
@property(nonatomic, strong) NSMutableArray *differentials;
@property(nonatomic, strong) EXTMultiplicationTables *multTables;
@property(nonatomic, assign, readonly) Class<EXTLocation> indexClass;
@property(nonatomic, strong) EXTLocationToPoint *locConvertor;
@property(nonatomic, strong) NSMutableArray *zeroRanges;

-(EXTSpectralSequence*) initWithIndexingClass:(Class<EXTLocation>)locClass;
+(EXTSpectralSequence*) sSeqWithIndexingClass:(Class<EXTLocation>)locClass;
+(EXTSpectralSequence*) sSeqWithUnit:(Class<EXTLocation>)locClass;
-(EXTSpectralSequence*) tensorWithSSeq:(EXTSpectralSequence*)p;

// TODO: these are misleading names, as they are nondestructive.
-(EXTSpectralSequence*) tensorWithPolyClass:(NSString*)name
                                   location:(EXTLocation*)loc
                                       upTo:(int)upTo;
-(EXTSpectralSequence*) tensorWithLaurentClass:(NSString*)name
                                      location:(EXTLocation*)loc
                                          upTo:(int)upTo
                                        downTo:(int)downTo;

- (EXTTerm*)findTerm:(EXTLocation*)loc;
- (void) addDifferential:(EXTDifferential*)diff;
- (EXTDifferential*)findDifflWithSource:(EXTLocation*)loc onPage:(int)page;
- (EXTDifferential*)findDifflWithTarget:(EXTLocation*)loc onPage:(int)page;
- (NSArray*)findDifflsSourcedUnderPoint:(EXTIntPoint)point onPage:(int)page;
- (NSArray*)findTermsUnderPoint:(EXTIntPoint)point;

-(void) computeGroupsForPage:(int)page;

// subclasses of EXTSpectralSequence can call this to be turned into plain old
// instances of EXTSpectralSequence.  this should be useful for e.g. tensoring
// together specialized spectral sequences of different sorts.
-(EXTSpectralSequence*) upcastToSSeq;

-(BOOL) isInZeroRanges:(EXTLocation*)loc;

-(void) naivelyPropagateLeibniz:(EXTLocation*)loc page:(int)page;
-(void) propagateLeibniz:(NSArray*)locations page:(int)page;
-(void) computeLeibniz:(EXTLocation *)loc1
                  with:(EXTLocation *)loc2
                onPage:(int)page;

@end
