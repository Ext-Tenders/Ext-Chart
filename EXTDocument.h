//
//  EXTDocument.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 Harvard University. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class EXTSpectralSequence;


@interface EXTDocument : NSDocument
    @property(nonatomic, strong) EXTSpectralSequence *sseq;
@end

// Notes: need something to specify the size (width, height) of the document, origin location, serre or adams convention?
