//
//  EXTFilteredModule.h
//  Ext Chart
//
//  Created by Michael Hopkins on 9/2/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EXTModule;
@class EXTMorphism;


@interface EXTFilteredModule : NSObject {

}

- (EXTModule *)rthModule:(int)r;
- (EXTModule *)rthCycles:(int)r;
- (EXTModule *)rthBoundaries:(int)r;
- (EXTMorphism *)inclusionMorphismFromB:(int) r toZ:(int)s;

- (void)insertNewCycleModuleAt:(int)r via:(EXTMorphism *)inclusionMap;
- (void)insertNewBoundaryModuleAt:(int)r via:(EXTMorphism *)quotientMap;

@end
