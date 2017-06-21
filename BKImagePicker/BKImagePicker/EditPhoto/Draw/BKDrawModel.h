//
//  BKDrawModel.h
//  BKImagePicker
//
//  Created by 兆林 on 2017/6/21.
//  Copyright © 2017年 BIKE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BKDrawView.h"

@interface BKDrawModel : NSObject

/**
 上次画的数组
 */
@property (nonatomic,strong) NSArray * pointArray;
/**
 选取的颜色
 */
@property (nonatomic,strong) UIColor * selectColor;
/**
 选取画的类型（颜色或马赛克）
 */
@property (nonatomic,assign) BKSelectType selectType;
/**
 画的形状
 */
@property (nonatomic,assign) BKDrawType drawType;

@end
