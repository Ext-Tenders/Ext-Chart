//
//  EXTPolynomialSSeq.h
//  Ext Chart
//
//  Created by Eric Peterson on 7/6/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "EXTSpectralSequence.h"
#import "EXTMultiplicationTables.h"



@interface EXTPolynomialTag : NSObject <NSCopying, NSCoding>

@property(strong) NSMutableDictionary *tags;

-(NSString*) description;
+(EXTPolynomialTag*) sum:(EXTPolynomialTag*)left with:(EXTPolynomialTag*)right;
-(BOOL) isEqual:(id)object;
-(instancetype) copyWithZone:(NSZone *)zone;

@end



// sometimes (oftentimes, actually), we know that a spectral sequence has an E1-
// page which is presented by a polynomial algebra.  this allows us to make
// some dramatic simplifications to how things are stored and computed.
@interface EXTPolynomialSSeq : EXTSpectralSequence

@property(strong,readonly) NSMutableArray *generators;

-(EXTPolynomialSSeq*) initWithIndexingClass:(Class<EXTLocation>)locClass;
+(EXTPolynomialSSeq*) sSeqWithIndexingClass:(Class<EXTLocation>)locClass;

-(void) addPolyClass:(NSObject<NSCopying>*)name location:(EXTLocation*)loc upTo:(int)bound;
-(void) resizePolyClass:(NSObject<NSCopying>*)name upTo:(int)newBound;

-(EXTMatrix*) productWithLeft:(EXTLocation*)left right:(EXTLocation*)right;

// performs an irreversible upcast to EXTSpectralSequence
-(EXTSpectralSequence*) upcastToSSeq;

-(void) computeLeibniz:(EXTLocation *)loc1
                  with:(EXTLocation *)loc2
                onPage:(int)page;

-(void) changeName:(NSObject<NSCopying>*)name to:(NSObject<NSCopying>*)newName;
-(void) deleteClass:(NSObject<NSCopying>*)name;

@end
