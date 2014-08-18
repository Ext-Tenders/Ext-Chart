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
@property (nonatomic, strong) EXTSpectralSequence *sequence;
@property (nonatomic, strong) EXTChartViewModel *viewModel;
@end

@implementation EXTChartViewModelTestCase

- (void)setUp {
    self.viewModel = [EXTChartViewModel new];
    self.viewModel.sequence = self.sequence;
}

- (void)testTermCells {
    for (NSInteger page = 0; page < _kNumberOfPagesToTest; ++page) {
        self.viewModel.currentPage = page;
        [self.viewModel reloadCurrentPage];

        NSMutableSet *gridLocations = [NSMutableSet new];

        for (EXTChartViewModelTermCell *termCell in self.viewModel.termCells) {
            XCTAssertGreaterThan(termCell.terms.count, 0, @"Cells should have at least one term");
            XCTAssertGreaterThan(termCell.totalRank, 0, @"Cells should have total rank greater than 0");

            NSString *gridLocationString = EXTStringFromIntPoint(termCell.gridLocation);
            [gridLocations addObject:gridLocationString];

            EXTChartViewModelTermCell *gridCell = [self.viewModel termCellAtGridLocation:termCell.gridLocation];
            XCTAssertEqual(termCell, gridCell, @"Cell mismatch at grid location");
        }

        XCTAssertEqual(gridLocations.count, self.viewModel.termCells.count, @"There must be at most one cell at a grid location");
    }
}

- (void)testTerms {
    for (NSInteger page = 0; page < _kNumberOfPagesToTest; ++page) {
        self.viewModel.currentPage = page;
        [self.viewModel reloadCurrentPage];

        for (EXTChartViewModelTermCell *termCell in self.viewModel.termCells) {
            for (EXTChartViewModelTerm *term in termCell.terms) {
                XCTAssertEqual(termCell, term.termCell, @"Reverse relationship term -> termCell should match expected cell");
                XCTAssertNotNil(term.modelTerm, @"Term should point to a model term");
                XCTAssertGreaterThan(term.dimension, 0, @"Term dimension should be greater than 0");

                if (term.differential) {
                    XCTAssertEqual(term, term.differential.startTerm, @"Term should match the differential start term");
                }
            }
        }
    }
}

- (void)testHReps {
    for (NSInteger page = 0; page < _kNumberOfPagesToTest; ++page) {
        self.viewModel.currentPage = page;
        [self.viewModel reloadCurrentPage];

        for (EXTChartViewModelTermCell *termCell in self.viewModel.termCells) {
            for (EXTChartViewModelTerm *term in termCell.terms) {
                XCTAssertEqual(term.dimension, term.homologyReps.count, @"Term dimension should match the number of hReps");

                NSMutableArray *allReps = [NSMutableArray new];
                for (EXTChartViewModelTermHomologyReps *hReps in term.homologyReps) {
                    XCTAssertEqual(term, hReps.term, @"Reverse relationship hReps -> term should match expected term");

                    NSUInteger repsIndex = [allReps indexOfObjectPassingTest:^BOOL(NSArray *reps, NSUInteger idx, BOOL *stop) {
                        return [reps isEqualToArray:hReps.representatives];
                    }];
                    XCTAssertEqual(repsIndex, NSNotFound, @"Homology representatives must be unique for a given term");

                    NSArray *lastRepresentatives = allReps.lastObject;
                    if (lastRepresentatives) {
                        XCTAssertGreaterThanOrEqual(hReps.representatives.count, lastRepresentatives.count, @"hReps must be in ascending order");
                        if (hReps.representatives.count == lastRepresentatives.count) {
                            NSUInteger count = hReps.representatives.count;
                            for (NSUInteger i = 0; i < count; ++i) {
                                XCTAssertGreaterThanOrEqual(hReps.representatives[i], lastRepresentatives[i], @"hReps must be in ascending order");
                            }
                        }
                    }

                    [allReps addObject:hReps.representatives];
                }
            }
        }
    }
}

- (void)testDifferentials {
    for (NSInteger page = 0; page < _kNumberOfPagesToTest; ++page) {
        self.viewModel.currentPage = page;
        [self.viewModel reloadCurrentPage];

        for (EXTChartViewModelDifferential *diff in self.viewModel.differentials) {
            XCTAssertNotNil(diff.modelDifferential, @"View model differentials should point to a model differential");
            XCTAssertNotNil(diff.startTerm, @"View model differentials should have a start term");
            XCTAssertNotNil(diff.endTerm, @"View model differentials should have a start term");
            XCTAssertGreaterThan(diff.lines.count, 0, @"View model differentials should have at least one line");
        }
    }
}

@end



@interface EXTChartViewModelTestCaseA1MSS : EXTChartViewModelTestCase
@end

@implementation EXTChartViewModelTestCaseA1MSS
- (void)setUp {
    self.sequence = [EXTDemos A1MSSDemo];
    [super setUp];
}
@end

@interface EXTChartViewModelTestCaseS5Demo : EXTChartViewModelTestCase
@end

@implementation EXTChartViewModelTestCaseS5Demo
- (void)setUp {
    self.sequence = [EXTDemos S5Demo];
    [super setUp];
}
@end

@interface EXTChartViewModelTestCaseKUhC2Demo : EXTChartViewModelTestCase
@end

@implementation EXTChartViewModelTestCaseKUhC2Demo
- (void)setUp {
    self.sequence = [EXTDemos KUhC2Demo];
    [super setUp];
}
@end



