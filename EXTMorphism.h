//
//  EXTMorphism.h
//  Ext Chart
//
//  Created by Michael Hopkins on 9/2/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EXTModule;
@class EXTFilteredModule;


@interface EXTMorphism : NSObject {
	EXTModule *domain;
	EXTModule *range;
}

+ (EXTMorphism *)pullbackOf:(EXTMorphism *)f with:(EXTMorphism *)g;
- (BOOL) monomorphism;

@end
