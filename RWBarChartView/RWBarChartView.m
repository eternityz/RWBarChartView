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
@property (nonatomic, assign) CGFloat fadingAreaWidth;
@property (nonatomic, assign) CGFloat needleLength;
@property (nonatomic, assign) CGFloat needlePadding;
@property (nonatomic, assign) CGFloat lastSectionGap;
@property (nonatomic, assign) CGFloat leftIndicatorPadding;
@property (nonatomic, assign) CGFloat rightIndicatorPadding;
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
    self.lastSectionGap = 0;
    self.axisFont = [UIFont systemFontOfSize:10];
    self.axisColor = [UIColor whiteColor];
    self.sectionTitleSizeCache = [NSMutableDictionary dictionary];
    self.contentHorizontalMargin = 5;
    self.needleLength = 5;
    self.needlePadding = 2;
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

- (CGFloat)leftIndicatorPadding
{
    if (_leftIndicatorPadding >= 0)
    {
        return _leftIndicatorPadding;
    }
    CGFloat padding = 0;
    
    if ([self.dataSource numberOfSectionsInBarChartView:self] <= 0)
    {
        return padding;
    }
    
    if ([self.dataSource barChartView:self numberOfBarsInSection:0] <= 0)
    {
        return padding;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    id<RWBarChartItemProtocol> lastItem = [self.dataSource barChartView:self barChartItemAtIndexPath:indexPath];
    CGSize textSize = [self highlightTextSizeForText:[lastItem text]];
    
    padding = MAX(padding, textSize.width / 2);
    
    _leftIndicatorPadding = padding;
    
    return _leftIndicatorPadding;
}

- (CGFloat)rightIndicatorPadding
{
    if (_rightIndicatorPadding >= 0)
    {
        return _rightIndicatorPadding;
    }
    
    CGFloat padding = 0; // CGRectGetWidth(self.bounds) / 3.0;
    
    
    // last item size
    NSInteger section = [self.dataSource numberOfSectionsInBarChartView:self] - 1;
    if (section < 0)
    {
        return padding;
    }
    NSInteger item = [self.dataSource barChartView:self numberOfBarsInSection:section] - 1;
    if (item < 0)
    {
        return padding;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
    id<RWBarChartItemProtocol> lastItem = [self.dataSource barChartView:self barChartItemAtIndexPath:indexPath];
    CGSize textSize = [self highlightTextSizeForText:[lastItem text]];
    
    padding = MAX(padding, textSize.width / 2);
    
    _rightIndicatorPadding = padding;
    return _rightIndicatorPadding;
}

- (void)reloadData
{
    self.showsHorizontalScrollIndicator = ![self.dataSource shouldShowItemTextForBarChartView:self];
    [self.itemCache removeAllObjects];
    
    NSArray *unused = nil;
    if ([self.dataSource barChartView:self shouldShowAxisAtRatios:&unused withLabels:&unused])
    {
        self.fadingAreaWidth = 50;
    }
    else
    {
        self.fadingAreaWidth = 0;
    }
    
    // will be updated on demand
    self.sectionTitleAreaHeight = -HUGE_VALF;
    self.itemTextAreaHeight = -HUGE_VALF;
    self.leftIndicatorPadding = -HUGE_VALF;
    self.rightIndicatorPadding = -HUGE_VALF;
    
    self.sectionTitleSizeCache = [NSMutableDictionary dictionary];
    
    CGFloat width = [self leftIndicatorPadding] + self.fadingAreaWidth;
    NSMutableArray *sectionRects = [NSMutableArray array];
    for (NSInteger isec = 0; isec < [self.dataSource numberOfSectionsInBarChartView:self]; ++isec)
    {
        NSInteger nItems = [self.dataSource barChartView:self numberOfBarsInSection:isec];
        CGFloat secWidth = self.barWidth * nItems;
        if (nItems > 0)
        {
            secWidth += (nItems - 1) * [self barPadding];
        }
        
        CGFloat headerWidth = [self headerWidthInSection:isec];
        
        if (isec == [self.dataSource numberOfSectionsInBarChartView:self] - 1)
        {
            self.lastSectionGap = MAX(headerWidth - secWidth, 0);
        }
        
        secWidth = MAX(secWidth, headerWidth) + 1.0;
        
        CGRect sectionRect = CGRectMake(width, 0, secWidth, self.bounds.size.height);
        [sectionRects addObject:[NSValue valueWithCGRect:sectionRect]];
        
        width += secWidth;
        
    }
    
    width += [self rightIndicatorPadding];
    
    self.sectionRects = sectionRects;
    
    self.contentSize = CGSizeMake(width, self.bounds.size.height);
    self.contentInset = UIEdgeInsetsMake(0, self.contentHorizontalMargin, 0, self.contentHorizontalMargin);
    
    [self setContentOffset:CGPointMake(width - self.bounds.size.width + self.contentHorizontalMargin, 0)];
    [self setNeedsDisplay];
}

- (NSRange)visibleSectionsInRect:(CGRect)rect
{
    if (self.sectionRects.count == 0)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    NSInteger first = [self.sectionRects indexOfObject:[NSValue valueWithCGRect:rect] inSortedRange:NSMakeRange(0, self.sectionRects.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(NSValue *rectValue1, NSValue *rectValue2) {
        return [@([rectValue1 CGRectValue].origin.x) compare:@([rectValue2 CGRectValue].origin.x)];
    }];
    
    if (first == NSNotFound)
    {
        return NSMakeRange(NSNotFound, 0);
    }
    
    first = MAX(first - 1, 0);
    
    NSInteger last = MIN(first + 1, (NSInteger)(self.sectionRects.count) - 1);
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
        _sectionTitleAreaHeight = self.sectionTitleFont.lineHeight + 2 * self.sectionTitleTextVerticalMargin + self.axisFont.lineHeight;
    }
    
    return _sectionTitleAreaHeight;
}

- (CGFloat)highlightPositionX
{
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat progress = self.bounds.origin.x / (self.contentSize.width - w);
    
    CGFloat x = self.bounds.origin.x + self.fadingAreaWidth + self.contentHorizontalMargin + [self leftIndicatorPadding] + self.barWidth / 2.0 + (w - self.lastSectionGap - [self rightIndicatorPadding] - [self leftIndicatorPadding] - self.barWidth - 2 * self.contentHorizontalMargin - self.fadingAreaWidth) * progress;
    
    // x = MAX(x, [self leftIndicatorPadding] + self.barWidth / 2.0);
    // x = MIN(x, self.contentSize.width - [self rightIndicatorPadding] - self.barWidth / 2.0 - self.lastSectionGap);
    
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
        _itemTextAreaHeight = self.itemTextFont.lineHeight + 2 * self.itemTextVerticalMargin + self.needleLength + self.needlePadding;
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
    rect.origin.y = [self sectionTitleAreaHeight]; // [self itemTextAreaHeight];
    rect.size.height = self.bounds.size.height - rect.origin.y - [self itemTextAreaHeight]; // [self sectionTitleAreaHeight];
    
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

- (void)addRoundedRect:(CGRect)rect withRadius:(CGFloat)radius context:(CGContextRef)ctx
{
    CGFloat minX = CGRectGetMinX(rect);
    CGFloat maxX = CGRectGetMaxX(rect);
    CGFloat minY = CGRectGetMinY(rect);
    CGFloat maxY = CGRectGetMaxY(rect);
    
    CGContextMoveToPoint(ctx, minX + radius, minY);
    CGContextAddArcToPoint(ctx, maxX, minY, maxX, minY + radius, radius);
    CGContextAddArcToPoint(ctx, maxX, maxY, maxX - radius, maxY, radius);
    CGContextAddArcToPoint(ctx, minX, maxY, minX, maxY - radius, radius);
    CGContextAddArcToPoint(ctx, minX, minY, minX + radius, minY, radius);
}

- (CGFloat)alphaForBarAtRect:(CGRect)rect
{
    CGFloat alpha = 1.0;
    
    NSArray *unused = nil;
    if (![self.dataSource barChartView:self shouldShowAxisAtRatios:&unused withLabels:&unused])
    {
        return alpha;
    }
    
    CGFloat left = CGRectGetMinX(rect);
    alpha = MIN(alpha, (left - self.bounds.origin.x) / self.fadingAreaWidth);
    
    // CGFloat right = CGRectGetMaxX(rect);
    // CGFloat w = CGRectGetWidth(self.bounds);
    // alpha = MIN(alpha, (self.bounds.origin.x + w - right) / self.fadingAreaWidth);
    
    alpha = 0.2 + alpha * 0.8;
    
    return alpha;
}

- (void)drawBarsForSection:(NSInteger)isec inRect:(CGRect)rect context:(CGContextRef)ctx didDrawHighlight:(out BOOL *)didDrawHighlight
{
    *didDrawHighlight = NO;
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
            
            CGRect rect = CGRectMake(x, y - h, w, h);
            
            CGContextSetFillColorWithColor(ctx, [color colorWithAlphaComponent:[self alphaForBarAtRect:rect]].CGColor);
            
            CGContextFillRect(ctx, rect);
            
            /*
            CGContextBeginPath(ctx);
            [self addRoundedRect:rect withRadius:w / 4 context:ctx];
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
             */
            
            y -= h;
        }
        
        if ([self.dataSource shouldShowItemTextForBarChartView:self])
        {
            CGFloat highlightX = [self highlightPositionX];
            NSString *text = nil;
            if (
                (x <= highlightX && x + w + self.barPadding >= highlightX) // needle inside bar
                || (x >= highlightX && isec == 0 && irow == 0) // first bar
                || (x + w + self.barPadding < highlightX
                    && isec == [self.dataSource numberOfSectionsInBarChartView:self] - 1
                    && irow == [self.dataSource barChartView:self numberOfBarsInSection:isec] - 1
                    ) // last bar
                )
            {
                CGRect highlightRect = barFrame;
                highlightRect.origin.y = y;
                highlightRect.size.height -= (y - CGRectGetMinY(barFrame));
                
                text = [[self.dataSource barChartView:self barChartItemAtIndexPath:indexPath] text];
                [self drawHighlightText:text withRealBarFrame:highlightRect inRect:rect context:ctx];
                *didDrawHighlight = YES;
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
    
    CGFloat titleAreaH = [self sectionTitleAreaHeight] - self.axisFont.lineHeight;
    CGFloat titleAreaY = 0; // CGRectGetMaxY(sectionRect) - titleAreaH + 2;
    
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

- (NSDictionary *)highlightTextAttr
{
    NSDictionary *attr = @{NSFontAttributeName:self.itemTextFont, NSForegroundColorAttributeName:self.itemTextColor};
    return attr;
}

- (CGSize)highlightTextSizeForText:(NSString *)text
{
    return [text sizeWithAttributes:[self highlightTextAttr]];
}

- (void)drawHighlightText:(NSString *)text withRealBarFrame:(CGRect)barFrame inRect:(CGRect)rect context:(CGContextRef)ctx
{
    if (![self.dataSource shouldShowItemTextForBarChartView:self])
    {
        return;
    }
    
    CGContextSetStrokeColorWithColor(ctx, self.itemTextBackgroundColor.CGColor);
    CGContextStrokeRect(ctx, barFrame);
    
    
    CGSize textSize = [self highlightTextSizeForText:text];
    
    CGPoint needle = CGPointMake([self highlightPositionX], CGRectGetMaxY(rect) - [self itemTextAreaHeight] + self.needlePadding);
    
    CGRect bgRect = CGRectZero;
    bgRect.size.width = textSize.width + 2 * self.itemTextHorizontalMargin;
    bgRect.origin.x = needle.x - bgRect.size.width / 2.0;
    bgRect.origin.y = needle.y + self.needleLength;
    bgRect.size.height = [self itemTextAreaHeight] - self.needleLength - self.needlePadding;
    
    
    CGContextBeginPath(ctx);
    
    CGContextMoveToPoint(ctx, needle.x, needle.y);
    CGContextAddLineToPoint(ctx, needle.x - self.barWidth / 2.0, needle.y + self.needleLength);
    CGContextAddLineToPoint(ctx, needle.x + self.barWidth / 2.0, needle.y + self.needleLength);
    CGContextAddLineToPoint(ctx, needle.x, needle.y);
    
    [self addRoundedRect:bgRect withRadius:3.0 context:ctx];
    
    CGContextClosePath(ctx);
    CGContextSetFillColorWithColor(ctx, self.itemTextBackgroundColor.CGColor);
    CGContextFillPath(ctx);
    
    [text drawAtPoint:CGPointMake(CGRectGetMinX(bgRect) + self.itemTextHorizontalMargin, CGRectGetMinY(bgRect) + (bgRect.size.height - textSize.height) / 2.0) withAttributes:[self highlightTextAttr]];
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
    
    CGFloat y = [self sectionTitleAreaHeight];
    CGFloat h = self.bounds.size.height - y - [self itemTextAreaHeight];
    
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
    BOOL didDrawHighlight = NO;
    for (NSInteger isec = visibleSections.location; isec < visibleSections.location + visibleSections.length; ++isec)
    {
        BOOL currDidDrawHighlight = NO;
        [self drawTitleForSection:isec inRect:rect context:ctx];
        [self drawBarsForSection:isec inRect:rect context:ctx didDrawHighlight:&currDidDrawHighlight];
        if (currDidDrawHighlight)
        {
            didDrawHighlight = YES;
        }
    }
    if (!didDrawHighlight)
    {
        [self drawHighlightText:@"N/A" withRealBarFrame:CGRectZero inRect:self.bounds context:ctx];
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

- (void)scrollToBarAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    CGRect barFrame = [self frameForBarAtIndexPath:indexPath];
    CGFloat barCenterX = CGRectGetMidX(barFrame);
    
    // let barCenterX = [self highlightX], find origin.x
    // highlightX = x + C1 + C2 * (x / C3) = x * (1 + C2 / C3) + C1
    // x = highlightX - C1 / (1 + C2 / C3)
    
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat x = (barCenterX - (self.fadingAreaWidth + self.contentHorizontalMargin + [self leftIndicatorPadding] + self.barWidth / 2.0))
    / (1 + (w - self.lastSectionGap - [self rightIndicatorPadding] - [self leftIndicatorPadding] - self.barWidth - 2 * self.contentHorizontalMargin - self.fadingAreaWidth) / (self.contentSize.width - w));
    
    [self setContentOffset:CGPointMake(x, 0) animated:animated];
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
