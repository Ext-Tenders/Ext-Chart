//
//  EXTdifferential.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/22/11.
//  Copyright 2011 Harvard. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class EXTPair;
@class EXTGrid;
@class EXTPage;


@interface EXTdifferential : NSObject <NSCoding> {
	EXTPair* start;
	EXTPair* end;
	int page;
	id source;
	id target;
	Class termType;
	
}

@property(retain) EXTPair* start;
@property(retain) EXTPair* end;
@property(assign) int page;
@property(retain) id source;
@property(retain) id target;

- (id) initWithPage:(int)whichPage Start:(EXTPair*)startLocation AndEnd:(EXTPair*)endLocation;
- (id) initWithPage:(int)whichPage AndStart:(EXTPair*) startLocation;
+ (EXTPair*) getEndFrom:(EXTPair*)start OnPage:(int)page;
+ (EXTPair*) getStartFrom:(EXTPair*)end OnPage:(int)page;
+ (id) differentialWithPage:(int)whichPage AndStart:(EXTPair*) startLocation;
- (void)drawWithSpacing:(CGFloat)spacing;

#pragma mark *** tools for calculation homology (must be overridden in subclasses) ***

- (id) kernel;   // returns a subclass of EXTTerm...maybe the differential knows about the subclass it is operating on
- (id) cokernel;  // returns a subclass of EXTTerm
- (void) replaceSourceByKernel;
- (void) replaceTargetByCokernel;


#pragma mark *** general Tool methods ***

+ (NSBezierPath *) makeHighlightPathAtPoint:(NSPoint)point onGrid:(EXTGrid *)theGrid onPage:(NSInteger)page;
+ (void)addSelfToSequence:(NSMutableArray *)pageSequence onPageNumber:(NSUInteger)pageNo atPoint:(NSPoint)point;



@end
