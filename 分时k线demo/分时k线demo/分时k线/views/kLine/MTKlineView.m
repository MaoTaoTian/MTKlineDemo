//
//  MTKlineView.m
//  分时k线demo
//
//  Created by tianmaotao on 2017/10/10.
//  Copyright © 2017年 tianmaotao. All rights reserved.
//

#import "MTKlineView.h"
#import "MTMianKLineView.h"
#import "MTTechView.h"
#import "UIColor+CurveChart.h"
#import "MTCurveChartGlobalVariable.h"
#import "MTTrackingCrossView.h"
#import "SJKlineModel.h"

@interface MTKlineView ()<MTMianKLineViewDelegate, MTTechViewDelegate , UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
//主k线
@property (nonatomic, strong) MTMianKLineView *mainKlineView;
//指标view
@property (nonatomic, strong) MTTechView *techView;
//十字光标
@property (nonatomic, strong) MTTrackingCrossView *trackingCrossView;
//当前需要实现的指标类型
@property (nonatomic, assign) SJCurveTechType techType;
//记录ScrollView上一次次滑动的偏移量
@property (nonatomic, assign) CGFloat previousScrollViewOffsetX;
//数据开始显示的位置
@property (nonatomic, assign) NSInteger showStartIndex;
//数据的长度
@property (nonatomic, assign) NSInteger showCount;
//长按手势计时器
@property (nonatomic, strong) NSTimer *longPressTimer;
@property (nonatomic, copy) NSArray *testTechArr;
@property (nonatomic, assign) NSInteger testIndex;
@end

@implementation MTKlineView
#pragma mark - init
- (void)dealloc {
    
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor assistBackgroundColor];
        self.previousScrollViewOffsetX = 0;
        // k线类型默认时日k
        self.kLineType = SJKlineType_Day;
        // 指标类型默认时成交量
        self.techType = SJCurveTechType_Volume;
        self.showCount = self.scrollView.frame.size.width / ([MTCurveChartGlobalVariable kLineGap] + [MTCurveChartGlobalVariable kLineWidth]);
        
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.frame.size.height / 2 - 5 + 50, 100, 30)];
        [btn setTitle:@"点我点我😊" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(testAction:) forControlEvents:UIControlEventTouchUpInside];
        btn.titleLabel.font = [UIFont systemFontOfSize:13];
        [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        NSLog(@"%@", self.scrollView);
        self.testTechArr = [NSArray arrayWithObjects:@(SJCurveTechType_Volume),@(SJCurveTechType_KDJ),@(SJCurveTechType_BOLL), @(SJCurveTechType_MACD), nil];
        self.testIndex = 0;
        [self addSubview:btn];
    }

    
    return self;
}

#pragma mark - public methods
- (void)updateDataWithKlineType:(SJKlineType)kLineType {
    //================================================================================
    //该方法作为刷新k线视图时调用
    //
    //================================================================================
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(kLineViewDataManager)]) {
        MTDataManager *newManager = [self.dataSource kLineViewDataManager];
        if (self.manager != newManager) {
            self.manager = newManager;
            
            [self updateScrollViewContenSize];
            
            //初始化状态显示最新的k线数据
            CGFloat mainKlineViewWidth = self.mainKlineView.frame.size.width;
            CGFloat scrollViewFirstOffsetX = self.scrollView.contentSize.width - mainKlineViewWidth;
            self.scrollView.contentOffset = CGPointMake(scrollViewFirstOffsetX, 0);

            //绘制主k线
            NSArray *mainKlineModels = [self.manager getMainKLineDatas];
            self.showStartIndex = mainKlineModels.count - self.showCount;
            self.mainKlineView.needDrawKlneModels = [self.manager getMainKLineDatasWithRange:NSMakeRange(self.showStartIndex, self.showCount)];
            [self.mainKlineView drawMainView];
            
            //绘制指标
            [self updateKLineViewAndTechViewData];
        }
    }
}

#pragma mark - private methods
- (void)updateKLineViewAndTechViewData {
    //刷新
    if (self.techType == SJCurveTechType_Volume) {
        self.techView.needDrawTechModels = [self.manager getMainKLineDatasWithRange:NSMakeRange(self.showStartIndex, self.showCount)];
        [self.techView drawTechViewWithType:SJCurveTechType_Volume];
    } else if (self.techType == SJCurveTechType_KDJ) {
        self.techView.needDrawTechModels = [self.manager getKDJDatasWithRange:NSMakeRange(self.showStartIndex, self.showCount)];
        [self.techView drawTechViewWithType:SJCurveTechType_KDJ];
    } else if (self.techType == SJCurveTechType_BOLL) {
        self.techView.needDrawTechModels = [self.manager getBOLLDatasWithRange:NSMakeRange(self.showStartIndex, self.showCount)];
        self.techView.needDrawKlineModels = [self.manager getMainKLineDatasWithRange:NSMakeRange(self.showStartIndex, self.showCount)];
        [self.techView drawTechViewWithType:SJCurveTechType_BOLL];
    } else if (self.techType == SJCurveTechType_MACD) {
        self.techView.needDrawTechModels = [self.manager getMACDDatasWithRange:NSMakeRange(self.showStartIndex, self.showCount)];
        [self.techView drawTechViewWithType:SJCurveTechType_MACD];
    }
}

#pragma mark - event response
- (void)testAction:(UIButton *)sender {
    self.testIndex++;
    if (self.testIndex > (self.testTechArr.count - 1)) {
        self.testIndex = 0;
    }
    NSNumber *num = self.testTechArr[self.testIndex];
    NSInteger index = [num integerValue];
    if (index == SJCurveTechType_Volume) {
        self.techType = SJCurveTechType_Volume;
    } else if (index == SJCurveTechType_KDJ) {
        self.techType = SJCurveTechType_KDJ;
    } else if (index == SJCurveTechType_BOLL) {
        self.techType = SJCurveTechType_BOLL;
    } else if (index == SJCurveTechType_MACD){
        self.techType = SJCurveTechType_MACD;
    }
    
    [self updateKLineViewAndTechViewData];
}

#pragma mark - UIScrollView delegate
- (void)scrollViewDidScroll:(UIScrollView*)scrollView{
    //================================================================================
    // 左右滑动逻辑说明：主k线view的宽度略大于整个k线视图的宽度，当左右滑动到主k线的边界点时，去刷新显示在主k线视图上的数据，并调整主k线视图的位置
    //================================================================================
    CGPoint scrollViewOffset = scrollView.contentOffset;
    CGFloat difValue = scrollViewOffset.x - self.previousScrollViewOffsetX;
    
    // 刷新主k线和指标view的位置
    self.techView.frame = CGRectMake(scrollViewOffset.x, self.techView.frame.origin.y, self.techView.frame.size.width, self.techView.frame.size.height);
    self.mainKlineView.frame = CGRectMake(scrollViewOffset.x, self.mainKlineView.frame.origin.y, self.mainKlineView.frame.size.width, self.mainKlineView.frame.size.height);
    
    if (ABS(difValue) < ([MTCurveChartGlobalVariable kLineGap] + [MTCurveChartGlobalVariable kLineWidth])) {
        return;
    }
    
    if (scrollViewOffset.x > 0 || scrollViewOffset.x < (self.scrollView.contentSize.width - self.mainKlineView.frame.size.width)) {
        //计算显示数据的起始位置,这个地方存在误差，先不处理，后面再处理
        self.showStartIndex = scrollViewOffset.x / ([MTCurveChartGlobalVariable kLineWidth] + [MTCurveChartGlobalVariable kLineGap]);
        
        //刷新主k线的数据
        self.mainKlineView.needDrawKlneModels = [self.manager getMainKLineDatasWithRange:NSMakeRange(self.showStartIndex, self.showCount)];
        [self.mainKlineView drawMainView];
        
        //绘制指标
        [self updateKLineViewAndTechViewData];
        
        self.previousScrollViewOffsetX = scrollViewOffset.x;
    }
}

#pragma mark - KLineMainView delegate
- (void)kLineMainViewLongPressExactPosition:(CGPoint)longPressPosition selectedIndex:(NSInteger)index longPressPrice:(CGFloat)price {
    [self.techView reDrawTechShowViewWithIndex:index];
    self.trackingCrossView.showValue = price;
    CGFloat trackingCrossViewPointX = longPressPosition.x;
    if (trackingCrossViewPointX < 0) {
        trackingCrossViewPointX = 0;
    }
    if (trackingCrossViewPointX > self.mainKlineView.frame.size.width) {
        trackingCrossViewPointX = self.mainKlineView.frame.size.width;
    }
    CGFloat trackingCrossViewPointY = longPressPosition.y;
    if (trackingCrossViewPointY < 0) {
        trackingCrossViewPointY = 0;
    }
    self.trackingCrossView.crossPoint = CGPointMake(trackingCrossViewPointX, trackingCrossViewPointY);
    [self.trackingCrossView updateTrackingCrossView];
}

#pragma mark - MTTechViewDelegate
- (void)techViewLongPressExactPosition:(CGPoint)longPressPosition selectedIndex:(NSInteger)index longPressValue:(CGFloat)longPressValue {
    [self.mainKlineView reDrawShowViewWithIndex:index];
    self.trackingCrossView.showValue = longPressValue;
    CGFloat trackingCrossViewPointX = longPressPosition.x;
    if (trackingCrossViewPointX < 0) {
        trackingCrossViewPointX = 0;
    }
    if (trackingCrossViewPointX > self.techView.frame.size.width) {
        trackingCrossViewPointX = self.techView.frame.size.width;
    }
    CGFloat trackingCrossViewPointY = longPressPosition.y+ self.techView.frame.origin.y;
    if (trackingCrossViewPointY > (self.techView.frame.size.height + self.techView.frame.origin.y) ) {
        trackingCrossViewPointY = self.techView.frame.size.height + self.techView.frame.origin.y;
    }
    self.trackingCrossView.crossPoint = CGPointMake(trackingCrossViewPointX, trackingCrossViewPointY);
    [self.trackingCrossView updateTrackingCrossView];
}

#pragma mark - event response
- (void)pinchMethod:(UIPinchGestureRecognizer *)pinch {
    static CGFloat oldScale = 1.0f;
    CGFloat difValue = pinch.scale - oldScale;
    
    CGFloat oldKLineWidth = [MTCurveChartGlobalVariable kLineWidth];
    CGFloat newKlineWidth = oldKLineWidth * (difValue > 0 ? (1 + MTCurveChartKLineScaleFactor) : (1 - MTCurveChartKLineScaleFactor));
    if (newKlineWidth >= MTCurveChartKLineMaxWidth) {
        return;
    }
    
    if(ABS(difValue) > MTCurveChartKLineScaleBound) {
        [MTCurveChartGlobalVariable setkLineWith:newKlineWidth];
        oldScale = pinch.scale;
        //更新显示蜡烛的数量
        NSInteger oldShowCount = self.showCount;
        self.showCount = self.scrollView.frame.size.width / ([MTCurveChartGlobalVariable kLineGap] + [MTCurveChartGlobalVariable kLineWidth]);
        NSInteger changeShowCount = oldShowCount - self.showCount;
        self.showStartIndex = self.showStartIndex + changeShowCount / 2;
        
        [self updateScrollViewContenSize];

        //
        CGFloat newScrollViewContentOffset = self.mainKlineView.frame.origin.x * (difValue > 0 ? (1 + MTCurveChartKLineScaleFactor) : (1 - MTCurveChartKLineScaleFactor));
        self.scrollView.contentOffset = CGPointMake(newScrollViewContentOffset, 0);
    }
}

- (void)updateScrollViewContenSize {
    CGFloat scrollViewWidth = self.scrollView.frame.size.width;
    CGFloat scrollViewContentWidth = ([MTCurveChartGlobalVariable kLineGap] + [MTCurveChartGlobalVariable kLineWidth]) * [self.manager getMainKLineDatas].count;
    if (scrollViewContentWidth < scrollViewWidth) {
        scrollViewContentWidth = scrollViewWidth + 1;
    }
    self.scrollView.contentSize = CGSizeMake(scrollViewContentWidth, self.scrollView.frame.size.height);
}

#pragma mark 长按手势执行方法
- (void)longPressMethod:(UILongPressGestureRecognizer *)longPress{
    if(UIGestureRecognizerStateChanged == longPress.state || UIGestureRecognizerStateBegan == longPress.state) {
        CGPoint location = [longPress locationInView:self.mainKlineView];
        //暂停滑动
        self.scrollView.scrollEnabled = NO;
        self.trackingCrossView.hidden = NO;
        if (self.longPressTimer) {
            //上一次计时操作无效，先移除掉
            [self.longPressTimer invalidate];
            self.longPressTimer = nil;
        }
        
        //主k线或者指标view的精确位置计算
        if (location.y > self.techView.frame.origin.y) {
            location = [longPress locationInView:self.techView];
            [self.techView longPressOrMovingAtPoint:location];
        } else {
            [self.mainKlineView longPressOrMovingAtPoint:location];
        }
    }
    
    if(longPress.state == UIGestureRecognizerStateEnded) {
        //隐藏十字光标
        self.scrollView.scrollEnabled = YES;
        
        self.longPressTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(hiddenTrackingCrossView:) userInfo:nil repeats:NO];
    }
}

- (void)hiddenTrackingCrossView:(NSTimer *)timer {
    [self.longPressTimer invalidate];
    self.longPressTimer = nil;
    self.trackingCrossView.hidden = YES;
    
    //恢复主k线和指标的详情数据（显示原始详情数据）
    [self.mainKlineView reDrawShowViewWithIndex:-1];
    [self.techView reDrawTechShowViewWithIndex:-1];
}

#pragma mark - 单击打手势
- (void)tapMethod:(UITapGestureRecognizer *)tapGesture {
    if (self.longPressTimer) {
        [self.longPressTimer invalidate];
        self.longPressTimer = nil;
    }
    self.trackingCrossView.hidden = YES;
    //恢复主k线和指标的详情数据（显示原始详情数据）
    [self.mainKlineView reDrawShowViewWithIndex:-1];
    [self.techView reDrawTechShowViewWithIndex:-1];
}

#pragma mark - setters and getters

- (UIView *)mainKlineView {
    if (!_mainKlineView) {
        _mainKlineView = [[MTMianKLineView alloc] initWithDelegate:self];
        CGFloat mainKlineViewHeight = self.frame.size.height / 2 + 50;
        CGFloat mainKlineViewWidth = self.scrollView.frame.size.width;
        _mainKlineView.frame = CGRectMake(0, 0, mainKlineViewWidth, mainKlineViewHeight);
        
        [self.scrollView addSubview:_mainKlineView];
    }
    
    return _mainKlineView;
}

- (MTTechView *)techView {
    if (!_techView) {
        CGFloat techViewWidth = self.scrollView.frame.size.width;
        CGFloat techViewHeight = self.frame.size.height / 2 - 20 - 50;
        _techView = [[MTTechView alloc] initWithFrame:CGRectMake(0, self.frame.size.height / 2 + 20 + 50, techViewWidth, techViewHeight)];
        _techView.delegate = self;
        [self.scrollView addSubview:_techView];
    }
    
    return _techView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.delegate = self;
        [self addSubview:_scrollView];
        
        //缩放手势
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchMethod:)];
        [_scrollView addGestureRecognizer:pinchGesture];
        
        //长按手势
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressMethod:)];
        [_scrollView addGestureRecognizer:longPressGesture];
        
        //点击手势
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapMethod:)];
        tapGesture.numberOfTapsRequired = 1;
        [_scrollView addGestureRecognizer:tapGesture];
    }
    
    return _scrollView;
}

- (MTTrackingCrossView *)trackingCrossView {
    if (!_trackingCrossView) {
        CGRect dateRect = CGRectMake(0, self.mainKlineView.frame.origin.y + self.mainKlineView.frame.size.height, self.mainKlineView.frame.size.width, self.techView.frame.origin.y -(self.mainKlineView.frame.origin.y + self.mainKlineView.frame.size.height));
        _trackingCrossView = [[MTTrackingCrossView alloc] initWithFrame:self.bounds crossPoint:CGPointZero dateRect:dateRect];
        _trackingCrossView.hidden = YES;
        
        [self addSubview:_trackingCrossView];
    }
    
    return _trackingCrossView;
}

@end
