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


#define PRESENT_FILE_VERSION 1
#define MINIMUM_FILE_VERSION_ALLOWED 1


@interface EXTDocument ()
    {
        // view configuration
        CGFloat gridSpacing;
        NSSize extDocumentSize;
        NSPoint extDocumentOrigin;
        NSColor *gridLineColor;
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
    
    NSMutableData* data = [NSMutableData data];
    NSKeyedArchiver* arch = [[NSKeyedArchiver alloc]
                             initForWritingWithMutableData:data];
    
    // TODO: at the moment, i'm just writing the model out to disk.  however,
    // the routine is structured so that we can add other keys to the root
    // object for other document settings, like spacing and color and so forth.
    [arch encodeObject:_sseq forKey:@"sseq"];
    [arch encodeInteger:PRESENT_FILE_VERSION forKey:@"fileVersion"];
    
    [arch finishEncoding];
    
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    int version = [unarchiver decodeIntegerForKey:@"fileVersion"];
    if (version < MINIMUM_FILE_VERSION_ALLOWED) {
        *outError = [NSError errorWithDomain:@"edu.harvard.math.ext-chart" code:(-1) userInfo:[NSDictionary dictionaryWithObject:@"This version of Ext Chart is not backwards-compatible with this data file." forKey:NSLocalizedDescriptionKey]];
        return NO;
    }
    
    self.sseq = [unarchiver decodeObjectForKey:@"sseq"];

    return YES;
}

@end
