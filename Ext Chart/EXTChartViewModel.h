//
//  EXTChartViewModel.h
//  Ext Chart
//
//  Created by Bavarious on 10/06/2014.
//  Copyright (c) 2014 Harvard University. All rights reserved.
//

@import Foundation;

#import "EXTChartInteractionType.h"
#import "EXTDocument.h"

@class EXTSpectralSequence;
@class EXTTerm;
@class EXTDifferential;
@class EXTGrid;
@class EXTChartViewModelTerm;
@class EXTChartViewModelTermCell;
@class EXTChartViewModelDifferential;


@interface EXTChartViewModel : NSObject
@property (nonatomic, weak) EXTSpectralSequence *sequence;

/// An array of EXTChartViewModelTermCell objects.
@property (nonatomic, readonly) NSArray *termCells;

/// An array of EXTViewModelDifferential objects.
@property (nonatomic, readonly) NSArray *differentials;

/// An array of EXTViewModelMultAnnotation objects.
@property (nonatomic, readonly) NSArray *multAnnotations;

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, weak) EXTGrid *grid;

@property (nonatomic, assign) EXTChartInteractionType interactionType;

@property (nonatomic, weak) id selectedObject; // TODO: Should this really be readwrite?

/// An array of dictionaries containing instructions on how to draw the
/// multiplication annotations. This is inherited from the parent EXTDocument.
@property (nonatomic, readonly) NSArray *multiplicationAnnotationRules;

/// A property-list-conforming dictionary representing the view model in a given page.
/// Term cells are ordered by gridLocation, first by x and then by y.
@property (nonatomic, readonly, copy) NSDictionary *propertyListRepresentation;

- (void)reloadCurrentPage;
- (EXTChartViewModelTerm *)viewModelTermForModelTerm:(EXTTerm *)term;
- (EXTChartViewModelDifferential *)viewModelDifferentialForModelDifferential:(EXTDifferential *)differential;
- (EXTChartViewModelTermCell *)termCellAtGridLocation:(EXTIntPoint)gridLocation;
@end


@interface EXTChartViewModelTermCell : NSObject
@property (nonatomic, readonly, assign) EXTIntPoint gridLocation;
@property (nonatomic, readonly, assign) NSInteger totalRank;

/// An array of EXTChartViewModelTerm objects.
@property (nonatomic, readonly, strong) NSArray *terms;

@property (nonatomic, readonly, copy) NSDictionary *propertyListRepresentation;
@end


@interface EXTChartViewModelTerm : NSObject
@property (nonatomic, readonly, strong) EXTTerm *modelTerm;
@property (nonatomic, readonly, weak) EXTChartViewModelTermCell *termCell;

/// An array of EXTChartViewModelTermHomologyReps instances. Note that EXTChartViewModelTerm.dimension is the number of EXTChartViewModelTermHomologyReps objects.
@property (nonatomic, readonly, copy) NSArray *homologyReps;

/// The number of homology representatives.
@property (nonatomic, readonly, assign) NSInteger dimension;

/// There’s at most one differential per (term, page).
@property (nonatomic, readonly, weak) EXTChartViewModelDifferential *differential;

@property (nonatomic, readonly, copy) NSDictionary *propertyListRepresentation;
@end


@interface EXTChartViewModelTermHomologyReps : NSObject
/// An unsorted array of integers.
@property (nonatomic, readonly, weak) EXTChartViewModelTerm *term;
@property (nonatomic, readonly, copy) NSArray *representatives;
@property (nonatomic, readonly, assign) NSInteger order;
@property (nonatomic, readonly, copy) NSDictionary *propertyListRepresentation;
@end


@interface EXTChartViewModelDifferential : NSObject
@property (nonatomic, readonly, strong) EXTDifferential *modelDifferential;
@property (nonatomic, readonly, strong) EXTChartViewModelTerm *startTerm;
@property (nonatomic, readonly, strong) EXTChartViewModelTerm *endTerm;

@property (nonatomic, readonly) NSDictionary *hRepAssignments;

/// An array of EXTChartViewModelDifferentialLine objects.
@property (nonatomic, readonly, copy) NSArray *lines;

@property (nonatomic, readonly, copy) NSDictionary *propertyListRepresentation;
@end


@interface EXTChartViewModelDifferentialLine : NSObject
@property (nonatomic, readonly, assign) NSInteger startIndex;
@property (nonatomic, readonly, assign) NSInteger endIndex;
@property (nonatomic, readonly, copy) NSDictionary *propertyListRepresentation;
@end


@interface EXTChartViewModelMultAnnotation : NSObject
@property (nonatomic, readonly, strong) NSDictionary *modelMultAnnotation;
@property (nonatomic, readonly, strong) EXTChartViewModelTerm *startTerm;
@property (nonatomic, readonly, strong) EXTChartViewModelTerm *endTerm;

@property (nonatomic, readonly) NSDictionary *hRepAssignments;

/// An array of EXTChartViewModelMultAnnoLine objects.
@property (nonatomic, readonly, copy) NSArray *lines;

@property (nonatomic, readonly, copy) NSDictionary *propertyListRepresentation;
@end


@interface EXTChartViewModelMultAnnoLine : NSObject
@property (nonatomic, readonly, assign) NSInteger startIndex;
@property (nonatomic, readonly, assign) NSInteger endIndex;
@property (nonatomic, readonly, copy) NSDictionary *propertyListRepresentation;
@end
