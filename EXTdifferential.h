//
//  EXTDifferential.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/22/11.
//  Copyright 2011 Harvard. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EXTDocument.h"
#import "EXTMatrix.h"
@class EXTPair;
@class EXTGrid;
@class EXTPage;

//
// TODO: a real question is how to implement "partial definitions" of a
// differential.  like if you know that dx = e but not the rest of the
// differential, which you compute later, what do you do?  add them?  adding
// requires a sort of orthogonal complement to make sure you don't muck up
// what's already there.  this seems like a pretty complicated problem...
//

// this class models a differential in the spectral sequence.
@interface EXTDifferential : NSObject <NSCoding>
    {
        EXTTerm *start, *end;
        int page;
        EXTMatrix *presentation;
        // some sort of presentation
    }

    @property(retain) EXTTerm *start, *end;
    @property(assign) int page;
    @property(retain) EXTMatrix *presentation;

    -(id) set:(EXTTerm *)start end:(EXTTerm *)end page:(int)page;
    +(id) newDifferential:(EXTTerm *)start end:(EXTTerm *)end page:(int)page;

    +(id) dealWithClick:(NSPoint)location document:(EXTDocument*)document;
@end

#if 0
@interface EXTDifferential : NSObject <NSCoding> {
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

+(id) dealWithClick:(NSPoint)location document:(EXTDocument*)document;

#pragma mark *** tools for calculation homology (must be overridden in subclasses) ***

- (id) kernel;   // returns a subclass of EXTTerm...maybe the differential knows about the subclass it is operating on
- (id) cokernel;  // returns a subclass of EXTTerm
- (void) replaceSourceByKernel;
- (void) replaceTargetByCokernel;


#pragma mark *** general Tool methods ***

+ (NSBezierPath *) makeHighlightPathAtPoint:(NSPoint)point onGrid:(EXTGrid *)theGrid onPage:(NSInteger)page;
+ (void)addSelfToSequence:(NSMutableArray *)pageSequence onPageNumber:(NSUInteger)pageNo atPoint:(NSPoint)point;

@end
#endif
