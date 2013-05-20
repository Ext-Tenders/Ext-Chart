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

@property(retain) NSMutableDictionary *tables;
@property(retain) EXTDocument *document;

-(id) init;

-(EXTMatrix*) getMatrixFor:(EXTPair*)loc1 with:(EXTPair*)loc2;

-(NSMutableArray*) multiplyClass:(NSMutableArray*)class1 at:(EXTPair*)loc1
                            with:(NSMutableArray*)class2 at:(EXTPair*)loc2;

@end
