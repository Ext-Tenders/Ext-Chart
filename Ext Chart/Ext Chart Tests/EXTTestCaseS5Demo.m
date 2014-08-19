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

    NSArray *termCells = [self.chartViewModel.termCells sortedArrayUsingComparator:^NSComparisonResult(EXTChartViewModelTermCell *cell1, EXTChartViewModelTermCell *cell2) {
        const EXTIntPoint p1 = cell1.gridLocation;
        const EXTIntPoint p2 = cell2.gridLocation;

        if (p1.x < p2.x) return NSOrderedAscending;
        if (p1.x > p2.x) return NSOrderedDescending;
        if (p1.y < p2.y) return NSOrderedAscending;
        if (p1.y > p2.y) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    // Using the same sort order as termCells
    NSArray *expectedLocations = @[
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){0, 0}],
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){0, 2}],
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){0, 4}],
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){1, 0}],
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){1, 2}],
                                   [NSValue extValueWithIntPoint:(EXTIntPoint){1, 4}],
                                   ];
    XCTAssertEqual(termCells.count, expectedLocations.count, "Number of expected term cells mismatch");

    for (NSUInteger i = 0; i < termCells.count; ++i) {
        EXTChartViewModelTermCell *termCell = termCells[i];

        XCTAssertTrue(EXTEqualIntPoints(termCell.gridLocation, [expectedLocations[i] extIntPointValue]), "Cell location mismatch");
        XCTAssertEqual(termCell.totalRank, 1, @"Each cell should have total rank 1");
        XCTAssertEqual(termCell.terms.count, 1, @"Each cell should have exactly one term");

        EXTChartViewModelTerm *term = [termCell.terms firstObject];
        XCTAssertEqual(term.dimension, 1, @"Term should have dimension 1");
        XCTAssertEqual(term.homologyReps.count, 1, @"Term should have 1 hReps class");

        EXTChartViewModelTermHomologyReps *hRepsClass = term.homologyReps.firstObject;
        XCTAssertEqual(hRepsClass.order, 0, @"hReps class’s order should be 0");
        XCTAssertEqual(hRepsClass.representatives.count, 1, @"hReps class list of representatives should have 1 element");
        XCTAssertEqual([hRepsClass.representatives.firstObject integerValue], 1, "hReps should be (1)");
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

// This is an experiment. We could have non-programmers write JSON or property list representations of the expected data
// and use this generic test.
// The problem is that the error is extremely generic—representations don’t match—which makes it harder to determine
// where the error lies. Alternatively, we could try to build a model from an external representation, and then use
// regular tests.
- (void)testJSONOnPage0 {
    [self goToPage:0];
    NSDictionary *propertyListRepresentation = self.chartViewModel.propertyListRepresentation;

    NSURL *expectedURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"S5Demo page 0" withExtension:@"json"];
    NSData *expectedData = [NSData dataWithContentsOfURL:expectedURL];
    NSDictionary *expectedRepresentation = [NSJSONSerialization JSONObjectWithData:expectedData options:0 error:NULL];

    XCTAssertNotNil(expectedRepresentation, @"Couldn’t read expected representation");
    XCTAssertEqualObjects(propertyListRepresentation, expectedRepresentation, @"View model doesn’t match expected representation");
}

@end
