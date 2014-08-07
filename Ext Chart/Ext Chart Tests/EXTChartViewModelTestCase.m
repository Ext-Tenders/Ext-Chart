//
//  EXTChartViewModelTestCase.m
//  Ext Chart
//
//  Created by Bavarious on 12/07/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "EXTChartViewModel.h"
#import "EXTDemos.h"


static const NSInteger _kNumberOfPagesToTest = 5;


@interface EXTChartViewModelTestCase : XCTestCase
@end

@implementation EXTChartViewModelTestCase

- (void)test {
    NSArray *sequences = @[
                           [EXTDemos workingDemo],
                           [EXTDemos S5Demo],
                           [EXTDemos KUhC2Demo],
                           [EXTDemos A1MSSDemo],
                           ];

    for (EXTSpectralSequence *sequence in sequences) {
        EXTChartViewModel *viewModel = [EXTChartViewModel new];
        viewModel.sequence = sequence;

        [self test:viewModel];
    }
}

- (void)test:(EXTChartViewModel *)viewModel {
    for (NSInteger page = 0; page < _kNumberOfPagesToTest; ++page) {
        viewModel.currentPage = page;
        [viewModel reloadCurrentPage];

        [self _testTermsInViewModel:viewModel];
        [self _testDifferentialsInViewModel:viewModel];
    }
}

- (void)_testTermsInViewModel:(EXTChartViewModel *)viewModel {
    for (EXTChartViewModelTermCell *termCell in viewModel.termCells) {
        XCTAssertGreaterThan(termCell.terms.count, 0, @"Cells should have at least one term");
        XCTAssertGreaterThan(termCell.totalRank, 0, @"Cells should have total rank greater than 0");

        for (EXTChartViewModelTerm *term in termCell.terms) {
            XCTAssertEqual(termCell, term.termCell, @"Reverse relationship term -> termCell should match expected term cell");
            XCTAssertNotNil(term.modelTerm, @"View model term should point to a model term");
            XCTAssertGreaterThan(term.dimension, 0, @"View model term dimension should be greater than 0");
        }
    }
}

- (void)_testDifferentialsInViewModel:(EXTChartViewModel *)viewModel {
    for (EXTChartViewModelDifferential *diff in viewModel.differentials) {
        XCTAssertNotNil(diff.modelDifferential, @"View model differentials should point to a model differential");
        XCTAssertNotNil(diff.startTerm, @"View model differentials should have a start term");
        XCTAssertNotNil(diff.endTerm, @"View model differentials should have a start term");
        XCTAssertGreaterThan(diff.lines.count, 0, @"View model differentials should have at least one line");
    }
}

@end
