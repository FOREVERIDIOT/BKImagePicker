//
//  BKEditImageViewController.m
//  BKImagePicker
//
//  Created by zhaolin on 2018/2/9.
//  Copyright © 2018年 BIKE. All rights reserved.
//

#import "BKEditImageViewController.h"
#import "BKImagePickerConst.h"
#import "BKImagePicker.h"
#import "BKDrawView.h"
#import "BKSelectColorView.h"
#import "BKDrawModel.h"
#import "BKImageCropView.h"
#import "BKEditImageBottomView.h"

@interface BKEditImageViewController ()<BKSelectColorViewDelegate,BKDrawViewDelegate>

@property (nonatomic,copy) NSString * imagePath;//图片路径

/**
 要修改的图片
 */
@property (nonatomic,strong) UIImageView * editImageView;
/**
 全图马赛克处理
 */
@property (nonatomic,strong) UIImage * mosaicImage;
@property (nonatomic,strong) CAShapeLayer * mosaicImageShapeLayer;

/**
 画图(包括线、圆角矩形、圆、箭头)
 */
@property (nonatomic,strong) BKDrawView * drawView;

/**
 是否正在绘画中
 */
@property (nonatomic,assign) BOOL isDrawingFlag;
/**
 停止绘画后倒计时时间（5s）
 */
@property (nonatomic,assign) NSInteger afterDrawTime;
/**
 倒计时定时器
 */
@property (nonatomic,strong) NSTimer * drawTimer;


@property (nonatomic,strong) BKEditImageBottomView * bottomView;



/**
 颜色选取
 */
@property (nonatomic,strong) BKSelectColorView * selectColorView;

@end

@implementation BKEditImageViewController

#pragma mark - 图片路径

-(NSString*)imagePath
{
    if (!_imagePath) {
        NSString * imageBundlePath = [[NSBundle mainBundle] pathForResource:@"BKImage" ofType:@"bundle"];
        _imagePath = [NSString stringWithFormat:@"%@",imageBundlePath];
    }
    return _imagePath;
}

-(UIImage*)imageWithImageName:(NSString*)imageName
{
    return [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",self.imagePath,imageName]];
}

#pragma mark - viewDidLoad

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self initTopNav];
    [self initBottomNav];
    
    [self editImageView];
    [self drawView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    ((BKImageNavViewController*)self.navigationController).customTransition.enble = NO;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    ((BKImageNavViewController*)self.navigationController).customTransition.enble = YES;
}

#pragma mark - 图片

-(void)setEditImage:(UIImage *)editImage
{
    //图片取正
    _editImage = [editImage editImageOrientation];
}

-(UIImageView*)editImageView
{
    if (!_editImageView) {
        _editImageView = [[UIImageView alloc]initWithFrame:[self calculataImageRect]];
        _editImageView.image = self.editImage;
        [self.view insertSubview:_editImageView atIndex:0];
        
        //全图做马赛克处理 添加在图片图层上
        CALayer * imageLayer = [CALayer layer];
        imageLayer.frame = _editImageView.bounds;
        imageLayer.contents = (id)self.mosaicImage.CGImage;
        [_editImageView.layer addSublayer:imageLayer];
        //添加遮罩shapeLayer
        [_editImageView.layer addSublayer:self.mosaicImageShapeLayer];
        imageLayer.mask = self.mosaicImageShapeLayer;
    }
    return _editImageView;
}

#pragma mark - 算imageView 的 rect

-(CGRect)calculataImageRect
{
    CGRect imageRect = CGRectZero;
    
    CGFloat scale = self.editImage.size.width / self.view.bk_width;
    CGFloat height = self.editImage.size.height / scale;
    
    if (height > self.view.bk_height) {
        imageRect.size.height = self.view.bk_height;
        scale = self.editImage.size.height / self.view.bk_height;
        imageRect.size.width = self.editImage.size.width / scale;
        imageRect.origin.x = (self.view.bk_width - imageRect.size.width) / 2.0f;
        imageRect.origin.y = 0;
    }else{
        imageRect.size.height = height;
        imageRect.size.width = self.view.bk_width;
        imageRect.origin.x = 0;
        imageRect.origin.y = (self.view.bk_height - imageRect.size.height) / 2.0f;
    }
    
    return imageRect;
}

#pragma mark - 马赛克图片

-(UIImage *)mosaicImage
{
    if (!_mosaicImage) {
        CIImage *ciImage = [CIImage imageWithCGImage:self.editImage.CGImage];
        //生成马赛克
        CIFilter *filter = [CIFilter filterWithName:@"CIPixellate"];
        [filter setValue:ciImage forKey:kCIInputImageKey];
        //马赛克像素大小
        [filter setValue:@(50) forKey:kCIInputScaleKey];
        CIImage *outImage = [filter valueForKey:kCIOutputImageKey];
        
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef cgImage = [context createCGImage:outImage fromRect:CGRectMake(0, 0, self.editImage.size.width, self.editImage.size.height)];
        _mosaicImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
    return _mosaicImage;
}

-(CAShapeLayer*)mosaicImageShapeLayer
{
    if (!_mosaicImageShapeLayer) {
        _mosaicImageShapeLayer = [CAShapeLayer layer];
        _mosaicImageShapeLayer.frame = self.editImageView.bounds;
        _mosaicImageShapeLayer.lineCap = kCALineCapRound;
        _mosaicImageShapeLayer.lineJoin = kCALineJoinRound;
        _mosaicImageShapeLayer.lineWidth = 20;
        _mosaicImageShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
        _mosaicImageShapeLayer.fillColor = [UIColor clearColor].CGColor;
    }
    return _mosaicImageShapeLayer;
}

#pragma mark - 画画

-(BKDrawView*)drawView
{
    if (!_drawView) {
        _drawView = [[BKDrawView alloc]initWithFrame:self.editImageView.frame];
        _drawView.delegate = self;
        [self.view insertSubview:_drawView atIndex:0];
    }
    return _drawView;
}

#pragma mark - BKDrawViewDelegate

/**
 画的马赛克轨迹
 
 @param pointArr 轨迹数组
 */
-(void)processingMosaicImageWithPathArr:(NSArray*)pointArr
{
    CGMutablePathRef path = CGPathCreateMutable();
    
    if ([pointArr count] > 0) {
        for (int i = 0; i < [pointArr count]; i++) {
            
            NSArray * nextPointArr = pointArr[i];
            
            CGPoint startPoint = CGPointFromString([NSString stringWithFormat:@"%@",nextPointArr[0]]);
            CGPathMoveToPoint(path, NULL, startPoint.x, startPoint.y);
            
            for (int j = 0; j < [nextPointArr count]-1; j++) {
                CGPoint endPoint = CGPointFromString([NSString stringWithFormat:@"%@",nextPointArr[j+1]]);
                CGPathAddLineToPoint(path, NULL, endPoint.x, endPoint.y);
            }
            
            CGMutablePathRef nextPath = CGPathCreateMutableCopy(path);
            self.mosaicImageShapeLayer.path = nextPath;
            
            CGPathRelease(nextPath);
        }
    }else{
        self.mosaicImageShapeLayer.path = nil;
    }
    
    CGPathRelease(path);
}

#pragma mark - 手势

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    point.x = point.x - self.editImageView.frame.origin.x;
    point.y = point.y - self.editImageView.frame.origin.y;
    self.drawView.beginPoint = point;
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    point.x = point.x - self.editImageView.frame.origin.x;
    point.y = point.y - self.editImageView.frame.origin.y;
    
    if (self.drawView.beginPoint.x != point.x || self.drawView.beginPoint.y != point.y) {
        switch (self.drawView.drawType) {
            case BKDrawTypeLine:
            {
                [self.drawView drawLineWithPoint:point];
            }
                break;
            case BKDrawTypeRoundedRectangle:
            {
                [self.drawView drawRoundedRectangleWithPoint:point];
            }
                break;
            case BKDrawTypeCircle:
            {
                [self.drawView drawCircleWithBeginPoint:self.drawView.beginPoint endPoint:point];
            }
                break;
            case BKDrawTypeArrow:
            {
                [self.drawView drawArrowWithBeginPoint:self.drawView.beginPoint endPoint:point];
            }
                break;
            default:
                break;
        }
        
        [self movedOption];
    }
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([self.drawView.pointArray count] > 0) {
        
        BKDrawModel * model = [[BKDrawModel alloc]init];
        model.pointArray = [self.drawView.pointArray copy];
        model.selectColor = self.drawView.selectColor;
        model.selectType = self.drawView.selectType;
        model.drawType = self.drawView.drawType;
        
        [self.drawView.lineArray addObject:model];
        [self.drawView.pointArray removeAllObjects];
    }
    
    [self moveEndOption];
}

/**
 滑动中
 */
-(void)movedOption
{
    self.isDrawingFlag = YES;
    self.afterDrawTime = 5;
}

/**
 滑动结束
 */
-(void)moveEndOption
{
    if (self.isDrawingFlag) {
        self.afterDrawTime = 5;
    }else {
        self.isDrawingFlag = YES;
    }
}

#pragma mark - initTopNav

-(void)initTopNav
{
    self.leftImageView.image = nil;
    self.leftLab.text = @"取消";
    
    self.rightImageView.image = [self imageWithImageName:@"save_s"];
}

-(void)leftNavBtnAction:(UIButton *)button
{
    [self.navigationController popViewControllerAnimated:NO];
}

-(void)rightNavBtnAction:(UIButton *)button
{
    [[BKImagePicker sharedManager] saveImage:[self createNewImage]];
}

#pragma mark - initBottomNav

-(void)initBottomNav
{
    self.bottomNavViewHeight = BK_SYSTEM_TABBAR_HEIGHT;
    [self.bottomNavView addSubview:self.bottomView];
}

-(BKEditImageBottomView*)bottomView
{
    if (!_bottomView) {
        _bottomView = [[BKEditImageBottomView alloc]init];
        BK_WEAK_SELF(self);
        [_bottomView setSelectTypeAction:^{
            BK_STRONG_SELF(self);
            
            strongSelf.bottomNavViewHeight = strongSelf.bottomView.bk_height + BK_SYSTEM_TABBAR_HEIGHT - BK_SYSTEM_TABBAR_UI_HEIGHT;
            
            switch (strongSelf.bottomView.selectEditType) {
                case BKEditImageSelectEditTypeDrawLine:
                {
                    
                }
                    break;
                    
                default:
                    break;
            }
        }];
    }
    return _bottomView;
}

#pragma mark - 生成图片

-(UIImage*)createNewImage
{
    BOOL flag = [UIApplication sharedApplication].statusBarHidden;
    CGFloat alpha1 = self.topNavView.alpha;
    CGFloat alpha2 = self.bottomNavView.alpha;
    
    [UIApplication sharedApplication].statusBarHidden = YES;
    self.topNavView.alpha = 0;
    self.bottomNavView.alpha = 0;
    
    _editImageView.image = nil;
    self.view.backgroundColor = [UIColor clearColor];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGRect rect = self.editImageView.frame;
    rect.origin.x = rect.origin.x * scale;
    rect.origin.y = rect.origin.y * scale;
    rect.size.width = rect.size.width * scale;
    rect.size.height = rect.size.height * scale;
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    image = [UIImage imageWithCGImage:imageRef];
    
    UIGraphicsBeginImageContext(CGSizeMake(_editImage.size.width, _editImage.size.height));
    [_editImage drawInRect:CGRectMake(0, 0, _editImage.size.width, _editImage.size.height)];
    [image drawInRect:CGRectMake(0, 0, _editImage.size.width, _editImage.size.height)];
    UIImage * reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (!flag) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
    if (alpha1 != 0) {
        self.topNavView.alpha = alpha1;
    }
    if (alpha2 != 0) {
        self.bottomNavView.alpha = alpha1;
    }
    
    _editImageView.image = _editImage;
    self.view.backgroundColor = [UIColor blackColor];
    
    return reSizeImage;
}


@end
