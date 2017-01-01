//
//  BKVideoAlbumItemView.m
//  BKImagePicker
//
//  Created by iMac on 16/11/2.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#import "BKVideoAlbumItemView.h"
#import "BKImagePickerConst.h"

@interface BKVideoAlbumItemView()

@property (nonatomic,assign) NSInteger allSecond;

@end

@implementation BKVideoAlbumItemView

-(instancetype)initWithFrame:(CGRect)frame allSecond:(NSInteger)allSecond
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        
        self.allSecond = allSecond;
    }
    return self;
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPathRef pathRef = CGPathCreateWithRect(self.frame, nil);
    CGContextAddPath(context, pathRef);
    CGContextClip(context);
    
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] = {
        102.0/255.0,102.0/255.0,102.0/255.0,0,
        0.0/255.0,0.0/255.0,0.0/255.0,0.8,
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, sizeof(colors)/(sizeof(colors[0])*4));
    CGColorSpaceRelease(rgb);
    
    CGPoint start = CGPointMake(0,self.bk_height - 20);
    CGPoint end = CGPointMake(0,self.bk_height);
    
    CGContextDrawLinearGradient(context, gradient ,start ,end ,kCGGradientDrawsBeforeStartLocation);
    CGGradientRelease(gradient);
    
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"BKImage" ofType:@"bundle"];
    UIImage * videoImage = [UIImage imageWithContentsOfFile:[bundlePath stringByAppendingString:@"/video.png"]];
    [videoImage drawInRect:CGRectMake(5, self.bk_height - 16, 14, 14)];
    
    
    NSString * timeStr = @"";
    if (self.allSecond > 60) {
        NSInteger second = self.allSecond%60;
        NSInteger minute = self.allSecond/60;
        
        NSString * secondStr = [NSString stringWithFormat:@"%ld",second];
        if ([secondStr length] == 1) {
            secondStr = [NSString stringWithFormat:@"0%ld",second];
        }
        
        timeStr = [NSString stringWithFormat:@"%ld:%@",minute,secondStr];
        
    }else{
        
        NSString * second = [NSString stringWithFormat:@"%ld",self.allSecond];
        if ([second length] == 1) {
            second = [NSString stringWithFormat:@"0%ld",self.allSecond];
        }
        
        timeStr = [NSString stringWithFormat:@"00:%@",second];
    }

    NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = NSTextAlignmentRight;
    
    NSDictionary * attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12],NSParagraphStyleAttributeName:paragraphStyle,NSForegroundColorAttributeName:[UIColor whiteColor]};
    [timeStr drawWithRect:CGRectMake(self.bk_width/2.0f-5, self.bk_height-16, self.bk_width/2.0f, 14) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
}

@end
