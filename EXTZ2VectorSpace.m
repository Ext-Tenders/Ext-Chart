//
//  EXTZ2VectorSpace.m
//  Ext Chart
//
//  Created by Michael Hopkins on 9/2/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import "EXTZ2VectorSpace.h"



@implementation EXTZ2VectorSpace

@synthesize dimension;

- (id) init{
	return [self initWithDimension:0];
}


- (id) initWithDimension:(int)d{
	if (self = [super init]) {
		dimension = d;
	};	
	return self;
}


+ (EXTZ2VectorSpace *) directSumOf:(EXTZ2VectorSpace *)V with:(EXTZ2VectorSpace *)W{
	return [[EXTZ2VectorSpace alloc] initWithDimension:[V dimension]+[W dimension]];
}
@end
