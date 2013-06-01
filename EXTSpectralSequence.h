//
//  EXTSpectralSequence.h
//  Ext Chart
//
//  Created by Eric Peterson on 5/31/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EXTLocation.h"
//#import "EXTTerm.h"
//#import "EXTdifferential.h"

@class EXTMultiplicationTables;
@class EXTTerm, EXTDifferential;

@interface EXTSpectralSequence : NSObject

@property(nonatomic, strong) NSMutableArray *terms;
@property(nonatomic, strong) NSMutableArray *differentials;
@property(nonatomic, strong) EXTMultiplicationTables *multTables;
@property(nonatomic, assign) Class<EXTLocation> indexClass;

+ (EXTSpectralSequence*) spectralSequence;
- (EXTSpectralSequence*) tensorWithSSeq:(EXTSpectralSequence*)p;
- (EXTSpectralSequence*) tensorWithClasses:(NSMutableArray*)classes
                             differentials:(NSMutableArray*)differentials
                                multTables:(EXTMultiplicationTables*)multTables;

// these are misleading names
-(EXTSpectralSequence*) tensorWithPolyClass:(NSString*)name
                                   location:(EXTLocation*)loc
                                       upTo:(int)upTo;
-(EXTSpectralSequence*) tensorWithLaurentClass:(NSString*)name
                                      location:(EXTLocation*)loc
                                          upTo:(int)upTo
                                        downTo:(int)downTo;

- (EXTTerm*)findTerm:(EXTLocation*)loc;
- (EXTDifferential*)findDifflWithSource:(EXTLocation*)loc onPage:(int)page;
- (EXTDifferential*)findDifflWithTarget:(EXTLocation*)loc onPage:(int)page;

-(void) computeGroupsForPage:(int)page;

#pragma mark - built-in demos

+(EXTSpectralSequence*) workingDemo;
+(EXTSpectralSequence*) randomDemo;
+(EXTSpectralSequence*) S5Demo;

@end
