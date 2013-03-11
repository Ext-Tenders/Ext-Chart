//
//  EXTZ2VectorSpace.h
//  Ext Chart
//
//  Created by Michael Hopkins on 9/2/11.
//  Copyright 2011 HLProducts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EXTZ2VectorSpace : NSObject {
	int dimension;
}

@property int dimension;

+ (EXTZ2VectorSpace *) directSumOf:(EXTZ2VectorSpace *)V with:(EXTZ2VectorSpace *)W;

- (id) initWithDimension:(int)d;


// need some display methods, maybe

@end
