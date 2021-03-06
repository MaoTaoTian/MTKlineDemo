//
//  MTTrackingCrossView.m
//  分时k线demo
//
//  Created by tianmaotao on 2017/10/17.
//  Copyright © 2017年 tianmaotao. All rights reserved.
//

#import "MTTrackingCrossView.h"
#import "UIColor+CurveChart.h"
#import "SJCurveChartConstant.h"

@interface MTTrackingCrossView ()
@property (nonatomic, assign) CGRect showValueRect;

@end

@implementation MTTrackingCrossView

- (instancetype)initWithFrame:(CGRect)frame crossPoint:(CGPoint)crossPoint dateRect:(CGRect)dateRect {
    if (self = [super initWithFrame:frame]) {
        self.crossPoint = crossPoint;
        self.dateRect = dateRect;
        self.backgroundColor = [UIColor clearColor];
        self.showValue = 0.0f;
        self.dateStr = @"1970/01/01";
        self.showValueRect = CGRectZero;
        self.userInteractionEnabled = NO;
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (self.crossPoint.x > self.frame.size.width || self.crossPoint.x  < 0 || self.crossPoint.y > self.frame.size.height || self.crossPoint.y < 0) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self drawSelectedPart:context];
    
    [self drawVerticalLine:context];
    
    [self drawHorizontalLine:context];
}

//竖线
- (void)drawVerticalLine:(CGContextRef)context {
    
    CGContextSetStrokeColorWithColor(context, [UIColor longPressLineColor].CGColor);
    CGContextSetLineWidth(context, MTCurveChartTrackingCrossLineWidth);
    
    const CGPoint verticalLinePoint1s[] = {CGPointMake(self.crossPoint.x, 0), CGPointMake(self.crossPoint.x, self.dateRect.origin.y)};
    CGContextStrokeLineSegments(context, verticalLinePoint1s, 2);
    
    const CGPoint verticalLinePoint2s[] = {CGPointMake(self.crossPoint.x, self.dateRect.origin.y + self.dateRect.size.height), CGPointMake(self.crossPoint.x, self.frame.size.height)};
    CGContextStrokeLineSegments(context, verticalLinePoint2s, 2);
    
}

//横线
- (void)drawHorizontalLine:(CGContextRef)context {
    if (self.crossPoint.y < self.dateRect.origin.y || self.crossPoint.y > (self.dateRect.origin.y + self.dateRect.size.height)) {
        CGPoint startPoint = CGPointZero;
        CGPoint endPoint = CGPointZero;
        if (self.showValueRect.origin.x > 0) {
            startPoint = CGPointMake(0, self.crossPoint.y);
            endPoint = CGPointMake(self.frame.size.width - self.showValueRect.size.width, self.crossPoint.y);
        } else {
            startPoint = CGPointMake(self.showValueRect.size.width, self.crossPoint.y);
            endPoint = CGPointMake(self.frame.size.width, self.crossPoint.y);
        }
        CGContextSetStrokeColorWithColor(context, [UIColor longPressLineColor].CGColor);
        CGContextSetLineWidth(context, MTCurveChartTrackingCrossLineWidth);
        const CGPoint horizontalLinePoints[] = {startPoint, endPoint};
        CGContextStrokeLineSegments(context, horizontalLinePoints, 2);
    }
}

- (void)drawSelectedPart:(CGContextRef)context{
    //绘制选中日期
//    CGContextSetStrokeColorWithColor(context, [UIColor mainTextColor].CGColor);
    NSDictionary *attribute = @{NSFontAttributeName:[UIFont systemFontOfSize:12],NSForegroundColorAttributeName:[UIColor mainTextColor]};
    CGRect textRect = [self rectOfNSString:self.dateStr attribute:attribute];
    CGFloat datePointX = self.crossPoint.x - textRect.size.width / 2;
    //x轴临界值判断
    if (datePointX < 0) {
        datePointX = 0;
    }
    if (datePointX > (self.bounds.size.width - textRect.size.width)) {
        datePointX = self.bounds.size.width - textRect.size.width;
    }
    CGRect dateDrawRect= CGRectMake(datePointX, self.dateRect.origin.y, textRect.size.width, textRect.size.height);
    CGContextSetFillColorWithColor(context, [UIColor longPressSelectedRectBgColor].CGColor);
    CGContextFillRect(context, dateDrawRect);
    [self.dateStr drawInRect:dateDrawRect withAttributes:attribute];
    
    //绘制选中价格
    if (self.crossPoint.y < self.dateRect.origin.y || self.crossPoint.y > (self.dateRect.origin.y + self.dateRect.size.height)) {
        NSString *priceText = [NSString stringWithFormat:@"%.2f",self.showValue];
        CGRect priceRect = [self rectOfNSString:priceText attribute:attribute];
        CGFloat pricePointY = self.crossPoint.y - priceRect.size.height / 2;
        CGFloat pricePointX = 0;
        //y轴临界值判断
        if (pricePointY < priceRect.size.height / 2) {
            pricePointY = priceRect.size.height / 2;
        }
        if (pricePointY > (self.bounds.size.height - priceRect.size.height)) {
            pricePointY = self.bounds.size.height - priceRect.size.height;
        }
        //x轴临界值判断
        if (self.crossPoint.x < priceRect.size.width + 10) {
            pricePointX = self.bounds.size.width - priceRect.size.width;
        }
        if (self.crossPoint.x > (self.bounds.size.width - priceRect.size.width - 10)) {
            pricePointX = 0;
        }
        
        self.showValueRect = CGRectMake(pricePointX, pricePointY, priceRect.size.width, priceRect.size.height);
        CGContextSetFillColorWithColor(context, [UIColor longPressSelectedRectBgColor].CGColor);
        CGContextFillRect(context, self.showValueRect);
        [priceText drawInRect:self.showValueRect withAttributes:attribute];
    }
}

- (void)updateTrackingCrossView {
    [self setNeedsDisplay];
}

- (CGRect)rectOfNSString:(NSString *)string attribute:(NSDictionary *)attribute {
    CGRect rect = [string boundingRectWithSize:CGSizeMake(MAXFLOAT, 0)
                                       options:NSStringDrawingTruncatesLastVisibleLine |NSStringDrawingUsesLineFragmentOrigin |
                   NSStringDrawingUsesFontLeading
                                    attributes:attribute
                                       context:nil];
    return rect;
}

@end
