//
//  ZFQTagLayout.h
//  TagLayoutDemo
//
//  Created by _ on 16/11/21.
//  Copyright © 2016年 zhaofuqiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZFQTagLayoutDelegate <NSObject>

/**
 This method is used to set the width of UICollectionViewCell at row,

 @param row index of UICollectionViewCell
 @return Actual size of UICollectionViewCell, the height will be ignored,
         Actually ZFQTagLayout only need to know the width of UICollectionViewCell, because cell height has been replaced by property itemHeight.
 */
- (CGSize)itemSizeAtRow:(NSUInteger)row;

@end


@interface ZFQTagLayout : UICollectionViewLayout

@property (nonatomic, assign) UIEdgeInsets edgeInsets;
@property (nonatomic,assign) CGFloat horizontalPadding; //列与列之间的间距
@property (nonatomic,assign) CGFloat verticalPadding;   //行与行之间的间距


/**
 You must init this value, normally this value should be equal to the width of the UICollectionView
 */
@property (nonatomic, assign) CGFloat preferMaxLayoutWidth;

/**
 This value refers to the height of the cell.
 */
@property (nonatomic, assign) CGFloat itemHeight;
@property (nonatomic, weak) id<ZFQTagLayoutDelegate> layoutDelegate;

@end

