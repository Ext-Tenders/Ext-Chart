//
//  EXTSpectralSequence.h
//  Ext Chart
//
//  Created by Eric Peterson on 5/31/13.
//  Copyright (c) 2013 HLProducts. All rights reserved.
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
- (EXTSpectralSequence*) tensorSSeqs:(EXTSpectralSequence*)p;
- (EXTSpectralSequence*) tensorWithClasses:(NSMutableArray*)classes
                             differentials:(NSMutableArray*)differentials
                                multTables:(EXTMultiplicationTables*)multTables;

- (EXTTerm*)findTerm:(EXTLocation*)loc;
- (EXTDifferential*)findDifflWithSource:(EXTLocation*)loc onPage:(int)page;
- (EXTDifferential*)findDifflWithTarget:(EXTLocation*)loc onPage:(int)page;

@end
