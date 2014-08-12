//
//  EXTTermLayer.m
//  Ext Chart
//
//  Created by Bavarious on 04/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import "EXTTermLayer.h"
#import "EXTChartViewModel.h"

NSString * const EXTTermLayerFontName = @"Palatino-Roman";

void EXTTermLayerMakeCellLayout(EXTTermCellLayout *outLayout, EXTChartViewModelTermCell *termCell) {
    NSCParameterAssert(outLayout);
    NSCParameterAssert(termCell);

    *outLayout = (EXTTermCellLayout){0};
    outLayout->rank = termCell.totalRank;

    if (outLayout->rank <= EXTTermLayerMaxGlyphs) {
        NSInteger glyphIndex = 0;

        for (EXTChartViewModelTerm *term in termCell.terms) {
            if (glyphIndex >= EXTTermLayerMaxGlyphs) {
                DLog(@"I think this shouldn’t happen");
                break;
            }

            const NSInteger dimension = term.dimension;

            for (NSInteger i = 0; i < dimension && glyphIndex < EXTTermLayerMaxGlyphs; ++i) {

                EXTChartViewModelTermHomologyReps *hReps = term.homologyReps[i];

                outLayout->glyphs[glyphIndex] = (hReps.order == 0 ?
                                                 EXTTermCellGlyphUnfilledSquare :
                                                 EXTTermCellGlyphFilledDot);
                ++glyphIndex;
            }
        }
    }
    else {
        outLayout->glyphs[0] = EXTTermCellGlyphUnfilledDotWithLabel; // TODO: not really needed apparently
    }
}
