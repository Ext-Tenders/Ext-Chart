//
//  EXTTestCaseS5Demo.m
//  Ext Chart
//
//  Created by Bavarious on 12/06/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EXTDemos.h"
#import "EXTChartViewModel.h"
#import "NSValue+EXTIntPoint.h"

@interface EXTTestCaseS5Demo : XCTestCase
@property (nonatomic, strong) EXTChartViewModel *chartViewModel;
@end

@implementation EXTTestCaseS5Demo

- (void)setUp
{
    [super setUp];

    self.chartViewModel = [EXTChartViewModel new];
    self.chartViewModel.sequence = EXTDemos.S5Demo;
}

- (void)goToPage:(NSInteger)targetPage
{
    for (NSInteger page = 0; page <= targetPage; ++page) {
        self.chartViewModel.currentPage = page;
        [self.chartViewModel reloadCurrentPage];
    }
}

- (void)testTermsOnPage0
{
    [self goToPage:0];

    NSArray *termCells = self.chartViewModel.termCells;
    XCTAssertEqual(termCells.count, 6, "S5 should have exactly six term cells in page 0");

    NSArray *expectedLocations = @[
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){0, 0}],
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){1, 4}],
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){0, 2}],
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){1, 0}],
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){0, 4}],
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){1, 2}],
                                   ];

    for (EXTChartViewModelTermCell *termCell in termCells) {
        const NSUInteger index = [expectedLocations indexOfObjectPassingTest:^BOOL(NSValue *locationValue, NSUInteger idx, BOOL *stop) {
            return EXTEqualIntPoints([locationValue extIntPointValue], termCell.gridLocation);
        }];

        XCTAssertNotEqual(index, NSNotFound, @"Term cell location is not expected");
        XCTAssertEqual(termCell.totalRank, 1, @"Each cell should have total rank 1");
        XCTAssertEqual(termCell.terms.count, 1, @"Each cell should have exactly one term");

        EXTChartViewModelTerm *term = [termCell.terms firstObject];
        XCTAssertEqual(term.dimension, 1, @"Term should have dimension 1");
    }
}

- (void)testDifferentialsOnPage0
{
    [self goToPage:0];

    NSArray *diffs = self.chartViewModel.differentials;
    XCTAssertEqual(diffs.count, 0, @"There should be no differentials on page 0");
}

- (void)testDifferentialsOnPage1
{
    [self goToPage:1];

    NSArray *diffs = self.chartViewModel.differentials;
    XCTAssertEqual(diffs.count, 0, @"There should be no differentials on page 1");
}

- (void)testDifferentialsOnPage2
{
    [self goToPage:2];

    NSArray *diffs = self.chartViewModel.differentials;
    XCTAssertEqual(diffs.count, 2, @"There should be two differentials on page 2");

    NSArray *differentialLocations0 = @[
                                        [NSValue extValueWithIntPoint:(EXTIntPoint){1, 0}],
                                        [NSValue extValueWithIntPoint:(EXTIntPoint){0, 2}],
                                        ];
    NSArray *differentialLocations1 = @[
                                        [NSValue extValueWithIntPoint:(EXTIntPoint){1, 2}],
                                        [NSValue extValueWithIntPoint:(EXTIntPoint){0, 4}],
                                        ];
    NSArray *expectedLocations = @[differentialLocations0, differentialLocations1];

    for (EXTChartViewModelDifferential *diff in diffs) {
        NSUInteger index = [expectedLocations indexOfObjectPassingTest:^BOOL(NSArray *locations, NSUInteger idx, BOOL *stop) {
            const EXTIntPoint startLocation = [locations[0] extIntPointValue];
            const EXTIntPoint endLocation = [locations[1] extIntPointValue];

            return (EXTEqualIntPoints(startLocation, diff.startTerm.termCell.gridLocation) &&
                    EXTEqualIntPoints(endLocation, diff.endTerm.termCell.gridLocation));
        }];

        XCTAssertNotEqual(index, NSNotFound, @"Differential start/end locations are not expected");
        XCTAssertEqual(diff.lines.count, 1, @"Each differential should have exactly one line");
        XCTAssertEqual([[diff.lines firstObject] startIndex], 0, @"Each differential line should have start index 0");
        XCTAssertEqual([[diff.lines firstObject] endIndex], 0, @"Each differential line should have end index 0");
    }
}
@end
