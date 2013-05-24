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


// this class models "partial definitions" of a differential.  for instance, we
// have inference code that determines the differential on the image of a cup
// product map E_{p, q} (x) E_{p', q'} --> E_{p+p', q+q'}.  there's no reason
// for that map to be surjective, so instead this determines the behavior of the
// differential only on the subspace that is its image.
//
// such partial definitions are not trivial to stitch together, and so to do
// that successfully, we just record all the definitions we have, together.
@interface EXTPartialDifferential : NSObject {
    EXTMatrix *inclusion;
    EXTMatrix *differential;
    bool automaticallyGenerated;
}

@property (retain) EXTMatrix *inclusion;
@property (retain) EXTMatrix *differential;
@property (assign) bool automaticallyGenerated;

@end



// this class models a differential in the spectral sequence.
// XXX: we don't implement NSCoding!
@interface EXTDifferential : NSObject <NSCoding>
    {
        EXTTerm *start, *end;
        int page;
        
        NSMutableArray *partialDefinitions; // array of EXTPartialDifferential's
        EXTMatrix *presentation;            // assembled from the array
        bool wellDefined;                   // false if definitions don't span
    }

    @property(retain) EXTTerm *start, *end;
    @property(assign) int page;
    @property(strong,readonly) NSMutableArray *partialDefinitions;
    @property(strong,readonly) EXTMatrix *presentation;
    @property(assign) bool wellDefined;

    // constructors
    +(id) newDifferential:(EXTTerm *)start end:(EXTTerm *)end page:(int)page;
    +(id) differential:(EXTTerm *)start end:(EXTTerm *)end page:(int)page;

    // deal wih its
    -(void) assemblePresentation;

    // UI messages
    -(void) drawWithSpacing:(CGFloat)spacing;
    +(id) dealWithClick:(NSPoint)location document:(EXTDocument*)document;
@end




// here's Mike's old class, in case i need to reference the interface for sth.
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
