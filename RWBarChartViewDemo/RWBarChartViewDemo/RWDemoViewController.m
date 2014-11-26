//
//  RWDemoViewController.m
//  RWBarChartViewDemo
//
//  Created by Zhang Bin on 14-03-08.
//  Copyright (c) 2014年 Zhang Bin. All rights reserved.
//

#import "RWDemoViewController.h"
#import "RWBarChartView.h"

@interface RWDemoViewController () <RWBarChartViewDataSource, UIScrollViewDelegate>

@property (nonatomic, strong) NSDictionary *singleItems; // indexPath -> RWBarChartItem
@property (nonatomic, strong) NSDictionary *statItems; // indexPath -> RWBarChartItem

@property (nonatomic, strong) NSArray *itemCounts;

@property (nonatomic, strong) RWBarChartView *singleChartView;
@property (nonatomic, strong) RWBarChartView *statChartView;

@property (nonatomic, strong) NSIndexPath *indexPathToScroll;

@end

@implementation RWDemoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        NSMutableArray *itemCounts = [NSMutableArray array];
        NSMutableDictionary *singleItems = [NSMutableDictionary dictionary];
        NSMutableDictionary *statItems = [NSMutableDictionary dictionary];
        
        // make sample values
        for (NSInteger isec = 0; isec < 5; ++isec)
        {
            NSInteger n = random() % 30 + 1;
            [itemCounts addObject:@(n)];
            for (NSInteger irow = 0; irow < n; ++irow)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:irow inSection:isec];
                
                // signle-segment item
                {
                    CGFloat ratio = (CGFloat)(random() % 1000) / 1000.0;
                    UIColor *color = nil;
                    if (ratio < 0.25)
                    {
                        color = [UIColor colorWithRed:0.5 green:0.5 blue:1.0 alpha:1.0];
                    }
                    else if (ratio < 0.5)
                    {
                        color = [UIColor colorWithRed:0.5 green:1.0 blue:0.5 alpha:1.0];
                    }
                    else if (ratio < 0.75)
                    {
                        color = [UIColor yellowColor];
                    }
                    else
                    {
                        color = [UIColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0];
                    }
                    
                    RWBarChartItem *singleItem = [RWBarChartItem itemWithSingleSegmentOfRatio:ratio color:color];
                    singleItem.text = [NSString stringWithFormat:@"Text %ld-%ld ", (long)indexPath.section, (long)indexPath.item];
                    singleItems[indexPath] = singleItem;
                }
                
                // multi-segment item
                {
                    NSMutableArray *ratios = [NSMutableArray array];
                    for (NSInteger rid = 0; rid < 3; ++rid)
                    {
                        [ratios addObject:@((CGFloat)(random() % 1000) / 1000.0)];
                    }
                    [ratios sortUsingSelector:@selector(compare:)];
                    for (NSInteger rid = ratios.count - 1; rid > 0; --rid)
                    {
                        ratios[rid] = @([ratios[rid] floatValue] - [ratios[rid - 1] floatValue]);
                    }
                    
                    RWBarChartItem *statItem = [RWBarChartItem new];
                    statItem.ratios = ratios;
                    statItem.colors = @[
                                        [UIColor colorWithRed:0.5 green:1.0 blue:0.5 alpha:1.0],
                                        [UIColor colorWithRed:1.0 green:1.0 blue:0.5 alpha:1.0],
                                        [UIColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0]
                                        ];
                    statItem.text = [NSString stringWithFormat:@"Text %ld-%ld ", (long)indexPath.section, (long)indexPath.item];
                    statItems[indexPath] = statItem;
                }
            }
        }
        
        self.itemCounts = itemCounts;
        self.singleItems = singleItems;
        self.statItems = statItems;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.singleChartView = [RWBarChartView new];
    self.singleChartView.dataSource = self;
    self.singleChartView.barWidth = 15;
    self.statChartView = [RWBarChartView new];
    self.statChartView.dataSource = self;
    self.statChartView.barWidth = 25;
    
    self.singleChartView.alwaysBounceHorizontal = YES;
    self.statChartView.alwaysBounceHorizontal = YES;
    
    self.singleChartView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1];
    self.statChartView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1];
    
    [self.view addSubview:self.singleChartView];
    [self.view addSubview:self.statChartView];
    
    self.singleChartView.scrollViewDelegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateScrollButton];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGFloat padding = 20;
    CGFloat height = (self.view.bounds.size.height - [self.topLayoutGuide length] - padding) / 2;
    CGRect rect = CGRectMake(0, [self.topLayoutGuide length], self.view.bounds.size.width, height);
    self.singleChartView.frame = rect;
    
    rect.origin.y = CGRectGetMaxY(rect) + padding;
    self.statChartView.frame = rect;
    
    [self.singleChartView reloadData];
    [self.statChartView reloadData];
    
}

- (NSInteger)numberOfSectionsInBarChartView:(RWBarChartView *)barChartView
{
    return self.itemCounts.count;
}

- (NSInteger)barChartView:(RWBarChartView *)barChartView numberOfBarsInSection:(NSInteger)section
{
    /*
    if (section == self.itemCounts.count - 1)
    {
        return 1;
    }
     */
    
    return [self.itemCounts[section] integerValue];
}

- (id<RWBarChartItemProtocol>)barChartView:(RWBarChartView *)barChartView barChartItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *items = (barChartView == self.singleChartView ? self.singleItems : self.statItems);
    return items[indexPath];
}

- (NSString *)barChartView:(RWBarChartView *)barChartView titleForSection:(NSInteger)section
{
    NSString *prefix = (barChartView == self.singleChartView ? @"Section" : @"Section");
    return [prefix stringByAppendingFormat:@" %ld", (long)section];
}

- (BOOL)shouldShowItemTextForBarChartView:(RWBarChartView *)barChartView
{
    return YES; // barChartView == self.singleChartView;
}

- (BOOL)barChartView:(RWBarChartView *)barChartView shouldShowAxisAtRatios:(out NSArray *__autoreleasing *)axisRatios withLabels:(out NSArray *__autoreleasing *)axisLabels
{
    if (barChartView == self.statChartView)
    {
        return NO;
    }
    
    *axisRatios = @[@(0.25), @(0.50), @(0.75), @(1.0)];
    *axisLabels = @[@"25%", @"50%", @"75%", @"100%"];
    
    return YES;
}

// example of UIScrollView events handling
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    NSLog(@"scrollViewDidEndDragging");
}

- (NSIndexPath *)indexPathToScroll
{
    if (!_indexPathToScroll)
    {
        NSInteger section = arc4random() % self.itemCounts.count;
        NSInteger item = arc4random() % [self.itemCounts[section] integerValue];
        _indexPathToScroll = [NSIndexPath indexPathForItem:item inSection:section];
    }
    return _indexPathToScroll;
}

- (void)updateScrollButton
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Scroll To %ld-%ld", (long)self.indexPathToScroll.section, (long)self.indexPathToScroll.item] style:UIBarButtonItemStylePlain target:self action:@selector(scrollToBar)];
}

- (void)scrollToBar
{
    [self.singleChartView scrollToBarAtIndexPath:self.indexPathToScroll animated:YES];
    [self.statChartView scrollToBarAtIndexPath:self.indexPathToScroll animated:YES];
    self.indexPathToScroll = nil;
    [self updateScrollButton];
}

@end
