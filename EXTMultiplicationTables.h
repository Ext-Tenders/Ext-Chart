//
//  EXTMultiplicationTables.h
//  Ext Chart
//
//  Created by Eric Peterson on 5/19/13.
//  Copyright (c) 2013 HLProducts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EXTMatrix.h"
#import "EXTDocument.h"

@interface EXTMultiplicationTables : NSObject
    {
        NSMutableDictionary *tables;
        EXTDocument *document;
    }

@property(strong) NSMutableDictionary *tables;
@property(strong) EXTDocument *document;

-(id) init;
+(id) multiplicationTables:(EXTDocument*)document;

-(EXTMatrix*) getMatrixFor:(EXTLocation*)loc1 with:(EXTLocation*)loc2;

-(NSMutableArray*) multiplyClass:(NSMutableArray*)class1 at:(EXTLocation*)loc1
                            with:(NSMutableArray*)class2 at:(EXTLocation*)loc2;

-(void) computeLeibniz:(EXTLocation*)loc1
                  with:(EXTLocation*)loc2
                onPage:(int)page;

@end
