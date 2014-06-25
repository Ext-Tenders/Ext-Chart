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
#import "EXTMarquee.h"
#import "EXTDocumentWindowController.h"
#import "EXTDemos.h"
#import "NSUserDefaults+EXTAdditions.h"
#import "NSKeyedArchiver+EXTAdditions.h"


#define PRESENT_FILE_VERSION 3
#define MINIMUM_FILE_VERSION_ALLOWED 3


@implementation EXTDocument

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _sseq = [EXTSpectralSequence new];
        _marquees = [NSMutableArray new];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        _gridColor = [defaults extColorForKey:EXTGridColorPreferenceKey];
        _gridEmphasisColor = [defaults extColorForKey:EXTGridEmphasisColorPreferenceKey];
        _axisColor = [defaults extColorForKey:EXTGridAxisColorPreferenceKey];
        _highlightColor = [defaults extColorForKey:EXTChartViewHighlightColorPreferenceKey];
        _gridSpacing = [defaults doubleForKey:EXTGridSpacingPreferenceKey];
        _gridEmphasisSpacing = [defaults integerForKey:EXTGridEmphasisSpacingPreferenceKey];
        _artBoardGridFrame = (EXTIntRect){{0}, {20, 15}};
    }
    return self;
}

#pragma mark - Window controllers

- (void)makeWindowControllers {
    [self addWindowController:[EXTDocumentWindowController new]];
}

- (EXTDocumentWindowController *)mainWindowController {
    return (self.windowControllers.count == 1 ? self.windowControllers[0] : nil);
}

#pragma mark - Document saving and loading

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSMutableData* data = [NSMutableData data];
    NSKeyedArchiver* arch = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

    [arch encodeInteger:PRESENT_FILE_VERSION forKey:@"fileVersion"];

    [arch encodeObject:_sseq forKey:@"sseq"];
    [arch encodeObject:_marquees forKey:@"marquees"];

    [arch encodeObject:_gridColor forKey:@"gridColor"];
    [arch encodeObject:_gridEmphasisColor forKey:@"gridEmphasisColor"];
    [arch encodeObject:_axisColor forKey:@"axisColor"];
    [arch encodeObject:_highlightColor forKey:@"highlightColor"];
    [arch encodeDouble:_gridSpacing forKey:@"gridSpacing"];
    [arch encodeInteger:_gridEmphasisSpacing forKey:@"gridEmphasisSpacing"];
    [arch extEncodeIntRect:_artBoardGridFrame forKey:@"artBoardGridFrame"];

    [arch finishEncoding];

    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];

    int version = [unarchiver decodeIntegerForKey:@"fileVersion"];
    if (version < MINIMUM_FILE_VERSION_ALLOWED) {
        if (outError) {
            *outError = [NSError errorWithDomain:@"edu.harvard.math.ext-chart"
                                            code:(-1)
                                        userInfo:@{NSLocalizedDescriptionKey : @"This version of Ext Chart is not backwards-compatible with this data file."}];
        }
        return NO;
    }

    self.sseq = [unarchiver decodeObjectForKey:@"sseq"];

    if ([unarchiver containsValueForKey:@"marquees"])
        self.marquees = [unarchiver decodeObjectForKey:@"marquees"];

    if ([unarchiver containsValueForKey:@"gridColor"])
        self.gridColor = [unarchiver decodeObjectForKey:@"gridColor"];

    if ([unarchiver containsValueForKey:@"gridEmphasisColor"])
        self.gridEmphasisColor = [unarchiver decodeObjectForKey:@"gridEmphasisColor"];

    if ([unarchiver containsValueForKey:@"axisColor"])
        self.axisColor = [unarchiver decodeObjectForKey:@"axisColor"];

    if ([unarchiver containsValueForKey:@"highlightColor"])
        self.highlightColor = [unarchiver decodeObjectForKey:@"highlightColor"];

    if ([unarchiver containsValueForKey:@"gridSpacing"])
        self.gridSpacing = [unarchiver decodeDoubleForKey:@"gridSpacing"];

    if ([unarchiver containsValueForKey:@"gridEmphasisSpacing"])
        self.gridEmphasisSpacing = [unarchiver decodeIntegerForKey:@"gridEmphasisSpacing"];

    EXTIntRect tentativeArtBoardGridFrame = [unarchiver extDecodeIntRectForKey:@"artBoardGridFrame"];
    if (tentativeArtBoardGridFrame.size.width > 0 && tentativeArtBoardGridFrame.size.height > 0)
        self.artBoardGridFrame = tentativeArtBoardGridFrame;

    return YES;
}

#pragma mark - Document features

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName {
    return YES;
}

@end
