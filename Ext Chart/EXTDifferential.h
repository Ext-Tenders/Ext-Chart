//
//  EXTDifferential.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/22/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

@import Foundation;

#import "EXTDocument.h"
#import "EXTMatrix.h"
#import "EXTTerm.h"
@class EXTGrid;
@class EXTPage;

// this class models a differential in the spectral sequence.
@interface EXTDifferential : NSObject <NSCoding, NSCopying>
{
    EXTTerm *start, *end;
    int page;
        
    NSMutableArray *partialDefinitions; // array of EXTPartialDifferential's
    bool wellDefined;                   // false if definitions don't span
}

@property(retain) EXTTerm *start, *end;
@property(assign) int page;
@property(strong,readonly) NSMutableArray *partialDefinitions;
@property(strong,readonly) EXTMatrix *presentation;
@property(assign) bool wellDefined;

// constructors
+(instancetype) newDifferential:(EXTTerm *)start
                            end:(EXTTerm *)end
                           page:(int)page;
+(instancetype) differential:(EXTTerm *)start
                         end:(EXTTerm *)end
                        page:(int)page;

// deal with its
-(void) assemblePresentation;
-(void) stripDuplicates;

-(BOOL) checkForSanity;

@end
