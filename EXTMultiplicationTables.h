//
//  EXTMultiplicationTables.h
//  Ext Chart
//
//  Created by Eric Peterson on 5/19/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EXTMatrix.h"
#import "EXTDocument.h"
#import "EXTSpectralSequence.h"

// the dictionary entries contain both precompiled matrices and partial def'ns.
@interface EXTMultiplicationEntry : NSObject {
    EXTMatrix *presentation;
    NSMutableArray *partialDefinitions;
}
@property(strong) EXTMatrix *presentation;
@property(strong) NSMutableArray *partialDefinitions;

-(EXTMultiplicationEntry*) init;
+(EXTMultiplicationEntry*) entry;

@end


// tracks a single multiplicative structure
@interface EXTMultiplicationTables : NSObject {
    NSMutableDictionary *tables;
    EXTDocument *document;
    EXTTerm *unitTerm;
    NSMutableArray *unitClass;
}

@property(strong) NSMutableDictionary *tables;
@property(strong) EXTSpectralSequence* sSeq;
@property(strong) EXTTerm *unitTerm;
@property(strong) NSMutableArray *unitClass;

-(id) init;
+(id) multiplicationTables:(EXTSpectralSequence*)sseq;

-(EXTMatrix*) getMatrixFor:(EXTLocation*)loc1 with:(EXTLocation*)loc2;

-(void) addPartialDefinition:(EXTPartialDefinition*)partial
                          to:(EXTLocation*)loc1
                        with:(EXTLocation*)loc2;

-(EXTMultiplicationEntry*) performLookup:(EXTLocation*)loc1
                                    with:(EXTLocation*)loc2;
-(EXTMultiplicationEntry*) performSoftLookup:(EXTLocation*)loc1
                                        with:(EXTLocation*)loc2;

-(NSMutableArray*) multiplyClass:(NSMutableArray*)class1 at:(EXTLocation*)loc1
                            with:(NSMutableArray*)class2 at:(EXTLocation*)loc2;

-(void) computeLeibniz:(EXTLocation*)loc1
                  with:(EXTLocation*)loc2
                onPage:(int)page;
-(void) naivelyPropagateLeibniz:(EXTLocation*)loc page:(int)page;
-(void) propagateLeibniz:(NSArray*)locations page:(int)page;

@end
