//
//  EXTDocument.h
//  Ext Chart
//
//  Created by Michael Hopkins on 7/20/11.
//  Copyright 2011 LH Productions. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "EXTLocation.h"
#import "EXTSpectralSequence.h"

@class EXTGrid, EXTArtBoard, EXTMultiplicationTables, EXTTerm, EXTDifferential;


@interface EXTDocument : NSDocument
    @property(nonatomic, strong) EXTSpectralSequence *sseq;

    - (void)randomize;

@end

// Notes: need something to specify the size (width, height) of the document, origin location, serre or adams convention?
