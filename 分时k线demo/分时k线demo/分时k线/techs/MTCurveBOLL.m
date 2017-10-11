//
//  MTCurveBOLL.m
//  分时k线demo
//
//  Created by tianmaotao on 2017/9/28.
//  Copyright © 2017年 tianmaotao. All rights reserved.
//

#import "MTCurveBOLL.h"
#import "SJKlineModel.h"
//计算过程：
//
//（1）计算MA
//MA=N日内的收盘价之和÷N
//（2）计算标准差MD
//MD=平方根（N-1）日的（C－MA）的两次方之和除以N
//（3）计算MB、UP、DN线
//MB=（N－1）日的MA
//UP=MB+k×MD
//DN=MB－k×MD
//（K为参数，可根据股票的特性来做相应的调整，一般默认为2）
//（N一般选择20天）
@implementation MTCurveBOLL
- (instancetype)init {
    if (self = [super init]) {
        self.curveTechType = SJCurveTechType_BOLL;
    }
    return self;
}

- (void)reckonTechWithArray:(NSArray<SJKlineModel *> *)baseDatas container:(NSArray<MTCurveObject *> *)supArray index:(NSInteger)index {
    [super reckonTechWithArray:baseDatas container:supArray index:index];
    //在此方法中计算指标
    SJKlineModel *model = baseDatas[index];
    if (index >= 19) {
//        计算过程：
//        （1）计算MA
//        MA=N日内的收盘价之和÷N
//        （2）计算标准差MD
//        MD=平方根（N-1）日的（C－MA）的两次方之和除以N
//        （3）计算MB、UP、DN线
//        MB=（N－1）日的MA
//        UP=MB+k×MD
//        DN=MB－k×MD
//        （K为参数，可根据股票的特性来做相应的调整，一般默认为2）
//        （N一般选择20天）
        if (index > 19) {
            self.MA20 = @((model.sumOfLastClose.floatValue - baseDatas[index - 19].sumOfLastClose.floatValue) / 19);
            
        } else {
            self.MA20 = @(model.sumOfLastClose.floatValue / index);
        }
        
        if (index >= 20) {
            self.BOLL_SUBMD = @((model.close.floatValue - self.MA20.floatValue) * ( model.close.floatValue - self.MA20.floatValue));
            MTCurveBOLL *previousCurveObject = (MTCurveBOLL *)supArray[index - 1];
            self.BOLL_SUBMD_SUM = @(previousCurveObject.BOLL_SUBMD_SUM.floatValue + self.BOLL_SUBMD.floatValue);
            MTCurveBOLL *curveObject20 = (MTCurveBOLL *)supArray[index - 20];
            self.BOLL_MD = @(sqrt((previousCurveObject.BOLL_SUBMD_SUM.floatValue - curveObject20.BOLL_SUBMD_SUM.floatValue)/ 20));
            self.BOLL_UP = @(self.BOLL_MB.floatValue + 2 * self.BOLL_MD.floatValue);
            self.BOLL_DN = @(self.BOLL_MB.floatValue - 2 * self.BOLL_MD.floatValue);
        }
    }
}

@end
