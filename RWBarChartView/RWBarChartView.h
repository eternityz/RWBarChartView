//
//  RWBarChartView.h
//  RWBarChartView
//
//  Created by Zhang Bin on 14-03-08.
//  Copyright (c) 2014年 Zhang Bin. All rights reserved.
//

@import UIKit;

/**
 *  Description of one bar in the chart. A single bar consists of one or more segments.
 */
@protocol RWBarChartItemProtocol <NSObject>

/**
 *  UIColors of the segments, from bottom to top.
 *
 *  @return NSArray of UIColor
 */
- (NSArray *)colors;

/**
 *  Ratios of the segments, from bottom to top.
 *  Each ratio should be a float NSNumber inside [0, 1].
 *
 *  @return NSArray of NSNumber
 */
- (NSArray *)ratios;

/**
 *  Text for this bar, will be displayed while scrolling 
 *  when ``-shouldShowItemTextForBarChartView:`` returns YES from the data source.
 */
- (NSString *)text;

@end


/**
 *  A simple implementation of ``RWBarChartItemProtocol``.
 */
@interface RWBarChartItem : NSObject <RWBarChartItemProtocol>

@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) NSArray *ratios;
@property (nonatomic, copy) NSString *text;

// Creates a bar of single segment.
+ (instancetype)itemWithSingleSegmentOfRatio:(CGFloat)ratio color:(UIColor *)color;

@end




@class RWBarChartView;



/**
 *  Data source protocol.
 */
@protocol RWBarChartViewDataSource <NSObject>

@required

/**
 *  Number of sections. Sections are divided horizontally.
 */
- (NSInteger)numberOfSectionsInBarChartView:(RWBarChartView *)barChartView;

/**
 *  Number of bars in each section.
 */
- (NSInteger)barChartView:(RWBarChartView *)barChartView numberOfBarsInSection:(NSInteger)section;

/**
 *  Description of a single bar for a given index path.
 */
- (id<RWBarChartItemProtocol>)barChartView:(RWBarChartView *)barChartView barChartItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Section titles that will be displayed on the horizontal axis.
 */
- (NSString *)barChartView:(RWBarChartView *)barChartView titleForSection:(NSInteger)section;

/**
 *  If this method returns YES, the rightmost visible bar will be highlighted,
 *  and text for this bar will be displayed on the top-right corner of the chart.
 */
- (BOOL)shouldShowItemTextForBarChartView:(RWBarChartView *)barChartView;


@optional
/**
 *  Optional vertical axis underneath the bars.
 *
 *  @param axisRatios   NSArray of float NSNumbers inside [0, 1]
 *  @param axisLabels   NSArray of NSStrings for each axis stop
 *
 *  @return YES to show the axis, NO to hide the axis
 */
- (BOOL)barChartView:(RWBarChartView *)barChartView shouldShowAxisAtRatios:(out NSArray **)axisRatios withLabels:(out NSArray **)axisLabels;

@end



@interface RWBarChartView : UIScrollView

/**
 *  Data source.
 */
@property (nonatomic, weak) id<RWBarChartViewDataSource> dataSource;

/**
 *  Delegate for UIScrollView events.
 */
@property (nonatomic, weak) id<UIScrollViewDelegate> scrollViewDelegate;

// Appearance tweeks
@property (nonatomic, assign) CGFloat barPadding;
@property (nonatomic, assign) CGFloat barWidth;
@property (nonatomic, assign) CGFloat sectionPadding;
@property (nonatomic, strong) UIFont *axisFont;
@property (nonatomic, strong) UIColor *axisColor;
@property (nonatomic, strong) UIFont *sectionTitleFont;
@property (nonatomic, strong) UIColor *sectionTitleColor;
@property (nonatomic, strong) UIColor *itemTextBackgroundColor;
@property (nonatomic, strong) UIColor *itemTextColor;
@property (nonatomic, strong) UIFont *itemTextFont;

/**
 *  Refresh the chart view.
 */
- (void)reloadData;

/**
 *  Scroll to a specific bar.
 */
- (void)scrollToBarAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

@end
