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
#import "EXTChartView.h"
#import "EXTGrid.h"

@interface EXTTestCaseS5Demo : XCTestCase
@property (nonatomic, strong) EXTSpectralSequence *sequence;
@property (nonatomic, strong) EXTGrid *grid;
@property (nonatomic, strong) EXTChartViewModel *chartViewModel;

@property (nonatomic, assign) EXTIntRect baseGridRect;
@end

@implementation EXTTestCaseS5Demo

- (void)setUp
{
    [super setUp];
    self.sequence = EXTDemos.S5Demo;

    self.grid = [EXTGrid new];
    self.grid.gridSpacing = 9.0;

    self.chartViewModel = [EXTChartViewModel new];
    self.chartViewModel.sequence = self.sequence;
    self.chartViewModel.grid = self.grid;

    self.baseGridRect = (EXTIntRect){{0, 0}, {2, 5}};
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

    NSArray *termCounts = [self.chartViewModel chartView:nil termCountsInGridRect:self.baseGridRect];
    XCTAssertEqual(termCounts.count, 6, "S5 should have exactly six term counts = six terms in page 0");

    NSArray *expectedTermsArray = @[
                                    [EXTChartViewTermCountData chartViewTermCountDataWithCount:1 location:(EXTIntPoint){0, 0}],
                                    [EXTChartViewTermCountData chartViewTermCountDataWithCount:1 location:(EXTIntPoint){1, 4}],
                                    [EXTChartViewTermCountData chartViewTermCountDataWithCount:1 location:(EXTIntPoint){0, 2}],
                                    [EXTChartViewTermCountData chartViewTermCountDataWithCount:1 location:(EXTIntPoint){1, 0}],
                                    [EXTChartViewTermCountData chartViewTermCountDataWithCount:1 location:(EXTIntPoint){0, 4}],
                                    [EXTChartViewTermCountData chartViewTermCountDataWithCount:1 location:(EXTIntPoint){1, 2}],
                                    ];
    NSSet *expectedTerms = [NSSet setWithArray:expectedTermsArray];
    NSSet *computedTerms = [NSSet setWithArray:termCounts];
    XCTAssertTrue([expectedTerms isEqualToSet:computedTerms], @"Term (and term counts) do not match");
}

- (void)testDifferentialsOnPage0
{
    [self goToPage:0];

    NSArray *diffs = [self.chartViewModel chartView:nil differentialsInGridRect:self.baseGridRect];
    XCTAssertEqual(diffs.count, 0, @"There should be no differentials on page 0");
}

- (void)testDifferentialsOnPage1
{
    [self goToPage:1];

    NSArray *diffs = [self.chartViewModel chartView:nil differentialsInGridRect:self.baseGridRect];
    XCTAssertEqual(diffs.count, 0, @"There should be no differentials on page 1");
}

- (void)testDifferentialsOnPage2
{
    [self goToPage:2];

    NSArray *diffs = [self.chartViewModel chartView:nil differentialsInGridRect:self.baseGridRect];
    XCTAssertEqual(diffs.count, 2, @"There should be two differentials on page 2");

    NSArray *expectedDiffsArray = @[
                                    [EXTChartViewDifferentialData chartViewDifferentialDataWithStartLocation:(EXTIntPoint){1, 0} startIndex:0 endLocation:(EXTIntPoint){0, 2} endIndex:0],
                                    [EXTChartViewDifferentialData chartViewDifferentialDataWithStartLocation:(EXTIntPoint){1, 2} startIndex:0 endLocation:(EXTIntPoint){0, 4} endIndex:0],
                                    ];
    NSSet *expectedDiffs = [NSSet setWithArray:expectedDiffsArray];
    NSSet *computedDiffs = [NSSet setWithArray:diffs];
    XCTAssertTrue([expectedDiffs isEqualToSet:computedDiffs], @"Differentials do not match");
}
@end
