//
//  RWBarChartView.m
//  RWBarChartView
//
//  Created by Zhang Bin on 14-03-08.
//  Copyright (c) 2014年 Zhang Bin. All rights reserved.
//

#import "RWBarChartView.h"

@interface RWBarChartView () <UIScrollViewDelegate>

@property (nonatomic, strong) NSArray *sectionRects;
@property (nonatomic, assign) CGFloat sectionTitleTextHorizontalMargin;
@property (nonatomic, assign) CGFloat sectionTitleTextVerticalMargin;
@property (nonatomic, assign) CGFloat sectionTitleAreaHeight;
@property (nonatomic, assign) CGFloat itemTextHorizontalMargin;
@property (nonatomic, assign) CGFloat itemTextVerticalMargin;
@property (nonatomic, assign) CGFloat itemTextAreaHeight;
@property (nonatomic, assign) CGFloat contentHorizontalMargin;
@property (nonatomic, assign) CGFloat needleLength;
@property (nonatomic, strong) NSMutableDictionary *sectionTitleSizeCache; // @(section) -> NSValue with CGSize
@property (nonatomic, strong) NSCache *itemCache;

@end

@implementation RWBarChartView

- (void)setup
{
    self.delegate = self;
    self.barPadding = 1.0;
    self.barWidth = 15;
    self.sectionPadding = 1.0;
    self.sectionTitleFont = [UIFont systemFontOfSize:12];
    self.sectionTitleTextHorizontalMargin = 5;
    self.sectionTitleTextVerticalMargin = 2;
    self.sectionTitleColor = [UIColor whiteColor];
    self.itemTextFont = [UIFont systemFontOfSize:12];
    self.itemTextColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.itemTextHorizontalMargin = 10;
    self.itemTextVerticalMargin = 2;
    self.itemTextBackgroundColor = [UIColor whiteColor];
    self.axisFont = [UIFont systemFontOfSize:10];
    self.axisColor = [UIColor whiteColor];
    self.sectionTitleSizeCache = [NSMutableDictionary dictionary];
    self.contentHorizontalMargin = 5;
    self.needleLength = 5;
    self.itemCache = [NSCache new];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([self.scrollViewDelegate respondsToSelector:aSelector])
    {
        return YES;
    }
    return [super respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self.scrollViewDelegate respondsToSelector:aSelector])
    {
        return self.scrollViewDelegate;
    }
    else
    {
        return [super forwardingTargetForSelector:aSelector];
    }
}

- (CGSize)titleSizeInSection:(NSInteger)section
{
    NSValue *cached = self.sectionTitleSizeCache[@(section)];
    if (cached)
    {
        return [cached CGSizeValue];
    }
    
    NSString *title = [self.dataSource barChartView:self titleForSection:section];
    CGSize titleSize = [title sizeWithAttributes:@{NSFontAttributeName:self.sectionTitleFont}];
    self.sectionTitleSizeCache[@(section)] = [NSValue valueWithCGSize:titleSize];
    return titleSize;
}

- (CGFloat)headerWidthInSection:(NSInteger)section
{
    CGSize titleSize = [self titleSizeInSection:section];
    return titleSize.width + 2 * self.sectionTitleTextHorizontalMargin + 1;
}

- (void)reloadData
{
    [self.itemCache removeAllObjects];
    
    // will be updated on demand
    self.sectionTitleAreaHeight = -HUGE_VALF;
    self.itemTextAreaHeight = -HUGE_VALF;
    
    // calculate content size
    self.sectionTitleSizeCache = [NSMutableDictionary dictionary];
    
    CGFloat width = 0;
    NSMutableArray *sectionRects = [NSMutableArray array];
    for (NSInteger isec = 0; isec < [self.dataSource numberOfSectionsInBarChartView:self]; ++isec)
    {
        NSInteger nItems = [self.dataSource barChartView:self numberOfBarsInSection:isec];
        CGFloat secWidth = self.barWidth * nItems;
        if (nItems > 0)
        {
            secWidth += (nItems - 1) * [self barPadding];
        }
        
        secWidth = MAX(secWidth, [self headerWidthInSection:isec]) + 1.0;
        
        CGRect sectionRect = CGRectMake(width, 0, secWidth, self.bounds.size.height);
        [sectionRects addObject:[NSValue valueWithCGRect:sectionRect]];
        
        width += secWidth;
    }
    self.sectionRects = sectionRects;
    
    self.contentSize = CGSizeMake(width, self.bounds.size.height);
    self.contentInset = UIEdgeInsetsMake(0, self.contentHorizontalMargin, 0, self.contentHorizontalMargin);
    
    [self setContentOffset:CGPointMake(width - self.bounds.size.width + self.contentHorizontalMargin, 0)];
    [self setNeedsDisplay];
}

- (NSRange)visibleSectionsInRect:(CGRect)rect
{
    NSInteger first = [self.sectionRects indexOfObject:[NSValue valueWithCGRect:rect] inSortedRange:NSMakeRange(0, self.sectionRects.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(NSValue *rectValue1, NSValue *rectValue2) {
        return [@([rectValue1 CGRectValue].origin.x) compare:@([rectValue2 CGRectValue].origin.x)];
    }];
    
    if (first == NSNotFound)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    first = MAX(first - 1, 0);
    
    NSInteger last = MIN(first + 1, self.sectionRects.count - 1);
    rect = [self.sectionRects[last] CGRectValue];
    
    while (last < self.sectionRects.count && CGRectIntersectsRect(self.bounds, [self.sectionRects[last] CGRectValue]))
    {
        ++last;
    }
    
    return NSMakeRange(first, last - first);
}

- (CGFloat)sectionTitleAreaHeight
{
    if (_sectionTitleAreaHeight < 0)
    {
        _sectionTitleAreaHeight = self.sectionTitleFont.lineHeight + 2 * self.sectionTitleTextVerticalMargin + 2;
    }
    
    return _sectionTitleAreaHeight;
}

- (CGFloat)highlightPositionX
{
    CGFloat x = CGRectGetMaxX(self.bounds) - self.barWidth / 2.0 - self.contentHorizontalMargin;
    
    NSInteger lastSection = [self.dataSource numberOfSectionsInBarChartView:self] - 1;
    if (lastSection >= 0)
    {
        NSInteger lastItem = [self.dataSource barChartView:self numberOfBarsInSection:lastSection] - 1;
        if (lastItem >= 0)
        {
            CGRect rect = [self frameForBarAtIndexPath:[NSIndexPath indexPathForItem:lastItem inSection:lastSection]];
            
            x = MIN(x, CGRectGetMidX(rect));
        }
    }
    
    if (self.bounds.origin.x < 0)
    {
        x += self.bounds.origin.x * 2.5;
    }
    
    return x;
}

- (CGFloat)itemTextAreaHeight
{
    if (_itemTextAreaHeight >= 0)
    {
        return _itemTextAreaHeight;
    }
    
    if ([self.dataSource shouldShowItemTextForBarChartView:self])
    {
        _itemTextAreaHeight = self.itemTextFont.lineHeight + 2 * self.itemTextVerticalMargin + self.needleLength;
    }
    else
    {
        _itemTextAreaHeight = 0;
    }
    
    return _itemTextAreaHeight;
}

- (CGRect)frameForBarAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect sectionRect = [self.sectionRects[indexPath.section] CGRectValue];
    
    CGRect rect = CGRectZero;
    rect.size.width = self.barWidth;
    rect.origin.x = sectionRect.origin.x + (rect.size.width + [self barPadding]) * indexPath.item;
    rect.origin.y = [self itemTextAreaHeight];
    rect.size.height = self.bounds.size.height - rect.origin.y - [self sectionTitleAreaHeight];
    
    return rect;
}

- (id<RWBarChartItemProtocol>)itemAtIndexPath:(NSIndexPath *)indexPath
{
    id<RWBarChartItemProtocol> item = [self.itemCache objectForKey:indexPath];
    if (!item)
    {
        item = [self.dataSource barChartView:self barChartItemAtIndexPath:indexPath];
        [self.itemCache setObject:item forKey:indexPath];
    }
    return item;
}

- (void)drawBarsForSection:(NSInteger)isec inRect:(CGRect)rect context:(CGContextRef)ctx
{
    for (NSInteger irow = 0; irow < [self.dataSource barChartView:self numberOfBarsInSection:isec]; ++irow)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:irow inSection:isec];
        CGRect barFrame = [self frameForBarAtIndexPath:indexPath];
        if (!CGRectIntersectsRect(rect, barFrame))
        {
            continue;
        }
        
        id<RWBarChartItemProtocol> item = [self itemAtIndexPath:indexPath];
        
        CGFloat w = barFrame.size.width;
        CGFloat y = CGRectGetMaxY(barFrame);
        CGFloat x = CGRectGetMinX(barFrame);
        
        for (NSUInteger idx = 0; idx < [item ratios].count; ++idx)
        {
            CGFloat ratio = [[item ratios][idx] floatValue];
            UIColor *color = [item colors][idx];
            
            CGFloat h = barFrame.size.height * ratio;
            
            CGContextSetFillColorWithColor(ctx, color.CGColor);
            CGContextFillRect(ctx, CGRectMake(x, y - h, w, h));
            
            y -= h;
        }
        
        if ([self.dataSource shouldShowItemTextForBarChartView:self])
        {
            CGFloat highlightX = [self highlightPositionX];
            if (x <= highlightX && x + w + self.barPadding >= highlightX)
            {
                CGRect highlightRect = barFrame;
                highlightRect.origin.y = y;
                highlightRect.size.height -= (y - CGRectGetMinY(barFrame));
                
                [self drawHighlightTextForItemAtIndexPath:indexPath withRealBarFrame:highlightRect inRect:rect context:ctx];
            }
        }
    }
}

- (void)drawTitleForSection:(NSInteger)isec inRect:(CGRect)rect context:(CGContextRef)ctx
{
    CGRect sectionRect = [self.sectionRects[isec] CGRectValue];
    if (!CGRectIntersectsRect(sectionRect, rect))
    {
        return;
    }
    
    CGFloat titleAreaH = [self sectionTitleAreaHeight];
    CGFloat titleAreaY = CGRectGetMaxY(sectionRect) - titleAreaH + 2;
    
    // draw separator line
    {
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, sectionRect.origin.x, titleAreaY);
        CGContextAddLineToPoint(ctx, sectionRect.origin.x, titleAreaY + titleAreaH);
        CGContextClosePath(ctx);
        CGContextSetStrokeColorWithColor(ctx, self.sectionTitleColor.CGColor);
        CGContextStrokePath(ctx);
    }
    
    // draw title text
    {
        CGSize titleSize = [self titleSizeInSection:isec];
        CGFloat titleX = MAX(CGRectGetMinX(sectionRect) + 1, CGRectGetMinX(self.bounds));
        titleX += self.sectionTitleTextHorizontalMargin;
        
        titleX = MIN(titleX, CGRectGetMaxX(sectionRect) - titleSize.width - self.sectionTitleTextHorizontalMargin);
        CGFloat titleY = titleAreaY + self.sectionTitleTextVerticalMargin;
        NSString *title = [self.dataSource barChartView:self titleForSection:isec];
        [title drawAtPoint:CGPointMake(titleX, titleY) withAttributes:@{NSFontAttributeName:self.sectionTitleFont, NSForegroundColorAttributeName:self.sectionTitleColor}];
    }
}

- (void)drawHighlightTextForItemAtIndexPath:(NSIndexPath *)indexPath withRealBarFrame:(CGRect)barFrame inRect:(CGRect)rect context:(CGContextRef)ctx
{
    if (![self.dataSource shouldShowItemTextForBarChartView:self])
    {
        return;
    }
    
    id<RWBarChartItemProtocol> item = [self.dataSource barChartView:self barChartItemAtIndexPath:indexPath];
    if (![item text])
    {
        return;
    }
    
    CGContextSetStrokeColorWithColor(ctx, self.itemTextBackgroundColor.CGColor);
    CGContextStrokeRect(ctx, barFrame);
    
    NSDictionary *attr = @{NSFontAttributeName:self.itemTextFont, NSForegroundColorAttributeName:self.itemTextColor};
    
    CGRect bgRect = CGRectZero;
    CGSize textSize = [[item text] sizeWithAttributes:attr];
    bgRect.size.width = textSize.width + 2 * self.itemTextHorizontalMargin;
    bgRect.origin.x = [self highlightPositionX] + self.barWidth / 2.0 - bgRect.size.width;
    bgRect.origin.y = CGRectGetMinY(rect);
    bgRect.size.height = [self itemTextAreaHeight] - self.needleLength;
    
    CGPoint needle = CGPointZero;
    
// #define RIGHT_TRIANGLE
#ifdef RIGHT_TRIANGLE
    // triangle points rightwards
    bgRect.origin.x -= self.barWidth;
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, CGRectGetMinX(bgRect), CGRectGetMinY(bgRect));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(bgRect), CGRectGetMinY(bgRect));
    needle = CGPointMake(CGRectGetMaxX(bgRect) + self.needleLength, CGRectGetMidY(bgRect));
    CGContextAddLineToPoint(ctx, needle.x, needle.y);
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(bgRect), CGRectGetMaxY(bgRect));
    CGContextAddLineToPoint(ctx, CGRectGetMinX(bgRect), CGRectGetMaxY(bgRect));
    CGContextClosePath(ctx);
    CGContextSetFillColorWithColor(ctx, self.itemTextBackgroundColor.CGColor);
    CGContextFillPath(ctx);
#else
    // triangle points downwards
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, CGRectGetMinX(bgRect), CGRectGetMinY(bgRect));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(bgRect), CGRectGetMinY(bgRect));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(bgRect), CGRectGetMaxY(bgRect));
    needle = CGPointMake(CGRectGetMaxX(bgRect) - self.barWidth / 2.0, CGRectGetMaxY(bgRect) + self.needleLength);
    CGContextAddLineToPoint(ctx, needle.x, needle.y);
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(bgRect) - self.barWidth, CGRectGetMaxY(bgRect));
    CGContextAddLineToPoint(ctx, CGRectGetMinX(bgRect), CGRectGetMaxY(bgRect));
    CGContextClosePath(ctx);
    CGContextSetFillColorWithColor(ctx, self.itemTextBackgroundColor.CGColor);
    CGContextFillPath(ctx);
#endif
    
#ifdef RIGHT_TRIANGLE
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, needle.x, needle.y);
    CGContextAddLineToPoint(ctx, needle.x, CGRectGetMinY(barFrame));
    CGContextClosePath(ctx);
    CGContextSetStrokeColorWithColor(ctx, self.itemTextBackgroundColor.CGColor);
    CGContextStrokePath(ctx);
#endif
    
    [[item text] drawAtPoint:CGPointMake(CGRectGetMinX(bgRect) + self.itemTextHorizontalMargin, CGRectGetMinY(bgRect) + (bgRect.size.height - textSize.height) / 2.0) withAttributes:attr];
}

- (void)drawAxisInRect:(CGRect)rect context:(CGContextRef)ctx
{
    NSArray *axisRatios = nil;
    NSArray *axisLabels = nil;
    
    if (![self.dataSource respondsToSelector:@selector(barChartView:shouldShowAxisAtRatios:withLabels:)]
        ||![self.dataSource barChartView:self shouldShowAxisAtRatios:&axisRatios withLabels:&axisLabels]
        )
    {
        return;
    }
    
    NSAssert(axisRatios.count == axisLabels.count, @"count of ratios and labels must be equal");
    
    NSDictionary *attrs = @{NSFontAttributeName:self.axisFont, NSForegroundColorAttributeName:self.axisColor};
    
    CGFloat y = [self itemTextAreaHeight];
    CGFloat h = self.bounds.size.height - y - [self sectionTitleAreaHeight];
    
    for (NSInteger idx = 0; idx < axisRatios.count; ++idx)
    {
        CGFloat ratio = [axisRatios[idx] floatValue];
        NSString *label = axisLabels[idx];
        CGSize labelSize = [label sizeWithAttributes:attrs];
        CGPoint p = CGPointMake(CGRectGetMinX(rect) + self.contentHorizontalMargin, y + h * (1 - ratio) - labelSize.height / 2);
        [label drawAtPoint:p withAttributes:attrs];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    [self drawAxisInRect:rect context:ctx];
    
    if (!self.sectionRects)
    {
        return;
    }
    
    NSRange visibleSections = [self visibleSectionsInRect:rect];
    if (visibleSections.location == NSNotFound)
    {
        return;
    }
    for (NSInteger isec = visibleSections.location; isec < visibleSections.location + visibleSections.length; ++isec)
    {
        [self drawTitleForSection:isec inRect:rect context:ctx];
        [self drawBarsForSection:isec inRect:rect context:ctx];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self setNeedsDisplay];
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)])
    {
        [self.scrollViewDelegate scrollViewDidScroll:scrollView];
    }
}

@end

@implementation RWBarChartItem

+ (instancetype)itemWithSingleSegmentOfRatio:(CGFloat)ratio color:(UIColor *)color
{
    RWBarChartItem *item = [self new];
    item.ratios = @[@(ratio)];
    item.colors = @[color];
    return item;
}

@end
