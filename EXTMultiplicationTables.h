//
//  EXTMultiplicationTables.h
//  Ext Chart
//
//  Created by Eric Peterson on 5/19/13.
//  Copyright (c) 2013 HLProducts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EXTPair.h"
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

-(EXTMatrix*) getMatrixFor:(EXTPair*)loc1 with:(EXTPair*)loc2;

-(NSMutableArray*) multiplyClass:(NSMutableArray*)class1 at:(EXTPair*)loc1
                            with:(NSMutableArray*)class2 at:(EXTPair*)loc2;

-(void) computeLeibniz:(EXTPair*)loc1 with:(EXTPair*)loc2 onPage:(int)page;

@end
