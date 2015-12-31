//
//  LCViewController.m
//  抽屉原理
//
//  Created by Mac on 14-12-4.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "LCViewController.h"

@interface LCViewController ()

@property (nonatomic, strong) UIView *leftView;
@property (nonatomic, strong) UIView *rigthView;
@property (nonatomic, strong) UIView *mainView;

/** 是否拖动 */
@property (nonatomic, assign, getter = isDraging) BOOL draging;
/** 是否动画 */
@property (nonatomic, assign, getter = isAnimating) BOOL animating;

@end

@implementation LCViewController


/** 用代码建立界面的视图层次结构(所有可见的视图全部创建) */
- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    // leftView
    self.leftView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.leftView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.leftView];
    
    // rightView
    self.rigthView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.rigthView.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.rigthView];
    
    // mainView
    self.mainView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.mainView.backgroundColor = [UIColor blueColor];
    [self.view addSubview:self.mainView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 添加一个观察者
    [self.mainView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // 如果动画设置frame，KVO不调整视图
    if (self.isAnimating) return;
    
    // 使用self.mainView的frame
    // 如果self.mainView.frame.origin.x > 0 向右
    if (self.mainView.frame.origin.x > 0) {
        // 显示左侧视图
        self.leftView.hidden = NO;
        self.rigthView.hidden = YES;
    } else {
        // 显示右侧视图
        self.leftView.hidden = YES;
        self.rigthView.hidden = NO;
    }
}

#pragma mark - 触摸事件

#define kMaxOffsetY     60.0

/** 使用偏移x值计算主视图目标的frame */
- (CGRect)rectWithOffsetX:(CGFloat)x
{
    CGSize winSize = [UIScreen mainScreen].bounds.size;
    // 1. 计算y
    CGFloat y = x * 60 / 320.0;
    // 2. 计算缩放比例
    CGFloat scale = (winSize.height - 2 * y) / winSize.height;
    
    // 如果 x<0 同样要缩小
    if (self.mainView.frame.origin.x < 0) {
        scale = 2 - scale;
    }
    
    // 3. 根据比例计算mainView新的frame
    CGRect frame = self.mainView.frame;
    // 3.1 宽度
    frame.size.width = frame.size.width * scale;
    frame.size.height = frame.size.height * scale;
    frame.origin.x += x;
    frame.origin.y = (winSize.height - frame.size.height) * 0.5;
    
    return frame;
}

// 拖动手指
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // 记录是拖动的
    self.draging = YES;
    
    // 取出触摸
    UITouch *touch = touches.anyObject;
    
    // 1> 当前触摸点
    CGPoint location = [touch locationInView:self.view];
    // 2> 之前触摸点
    CGPoint pLocation = [touch previousLocationInView:self.view];
    // 计算水平偏移量
    CGFloat offsetX = location.x - pLocation.x;
    
    // 3> 设置视图位置
    //    self.mainView.transform = CGAffineTransformTranslate(self.mainView.transform, offsetX, 0);
    self.mainView.frame = [self rectWithOffsetX:offsetX];
}

// 抬起手指时，让主视图定位
#define kMaxRightX      280.0
#define kMaxLeftX       -220.0

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // 如果不是拖动的，直接恢复位置
    if (!self.isDraging && self.mainView.frame.origin.x != 0) {
        [self restoreLocation];
        return;
    }
    
    // 需要根据mainView.x值来确定目标位置
    // 1> x > w * 0.5 => 挪到右边去 =》 目标的X
    // 2> x + width < w * 0.5 => 挪到左边去 => 目标X
    // 3> 其他的和主窗口一般大小 => 目标的X
    CGRect frame = self.mainView.frame;
    CGSize winSize = [UIScreen mainScreen].bounds.size;
    
    CGFloat targetX = 0;
    if (frame.origin.x > winSize.width * 0.5) {
        targetX = kMaxRightX;
    } else if (CGRectGetMaxX(frame) < winSize.width * 0.5) {
        targetX = kMaxLeftX;
    }
    // 计算出水平偏移量
    CGFloat offsetX = targetX - frame.origin.x;
    
    self.animating = YES;
    [UIView animateWithDuration:0.25 animations:^{
        if (targetX != 0) {
            self.mainView.frame = [self rectWithOffsetX:offsetX];
        } else {
            self.mainView.frame = self.view.bounds;
        }
    } completion:^(BOOL finished) {
        self.draging = NO;
        self.animating = NO;
    }];
}

// 恢复位置
- (void)restoreLocation
{
    self.animating = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.mainView.frame = self.view.bounds;
    } completion:^(BOOL finished) {
        self.animating = NO;
    }];
}

@end
