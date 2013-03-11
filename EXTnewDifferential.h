//
//  EXTnewDifferential.h
//  Ext Chart
//
//  Created by Michael Hopkins on 9/4/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class EXTPair;
@class EXTFilteredModule;
@class EXTMorphism;


@interface EXTnewDifferential : NSObject {
	EXTPair *sourceIndex;
	EXTPair *targetIndex;
	EXTFilteredModule *sourceFilteredModule;
	EXTFilteredModule *targetFilteredModule;
	EXTMorphism *differentialMorphism;
}

- (EXTMorphism *)factorMorphismSourceThrough:(EXTMorphism *)newSource;
- (EXTMorphism *)factorMorphismTargetThrough:(EXTMorphism *)newTarget;

@end
