//
//  EXTDocument.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTDocument.h"
#import "EXTChartView.h"
#import "EXTGrid.h"
#import "EXTArtBoard.h"
#import "EXTDocumentWindowController.h"
#import "EXTDemos.h"


@interface EXTDocument ()
    {
        // view configuration
        CGFloat gridSpacing;
        CGFloat gridScalingFactor;
        NSSize extDocumentSize;
        NSPoint extDocumentOrigin;
        //	extern CGFloat gridSpacing;
        //	extern NSRect canvasRect;
        NSColor *gridLineColor;
        NSColor *emphasGridLineColor;
    }

    @property(nonatomic, weak) EXTDocumentWindowController *windowController;
@end

@implementation EXTDocument

#pragma mark - Lifecycle

- (id)init {
    // upcall.
    self = [super init];
    
    // if we succeeded...
    if (self) {
        // allocate the display parts of things
        
        _sseq = [EXTSpectralSequence new];
    }

    return self;
}

// if requested, we can initialize the terms array with some test garbage
-(EXTSpectralSequence*) runDemo {
    // XXX: this should set the current page to 0, but bavarious changed sth...
    return self.sseq = [EXTDemos workingDemo];
}

#pragma mark - Window controllers

- (void)makeWindowControllers
{
    [self addWindowController:[EXTDocumentWindowController new]];
}

- (EXTDocumentWindowController *)windowController
{
    return (self.windowControllers.count == 1 ? self.windowControllers[0] : nil);
}

#pragma mark - Document saving and loading / TODO: THESE ARE DISABLED ***

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
//	return[NSKeyedArchiver archivedDataWithRootObject:[self pages]];
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}

	// TODO: review this
//	NSArray* arr = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//	NSMutableArray* marr = [arr mutableCopy];
//	
//	[self setPages:marr];
    return YES;
}

@end
