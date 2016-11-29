//
//  ZFQTagLayout.m
//  TagLayoutDemo
//
//  Created by _ on 16/11/21.
//  Copyright © 2016年 zhaofuqiang. All rights reserved.
//

#import "ZFQTagLayout.h"
@interface ZFQTagLayout()
{
    CGSize _contentSize;
    
    NSMutableArray<UICollectionViewCell *> *_allItems;
    NSMutableArray<UICollectionViewLayoutAttributes *> *_allLayoutAttributes;
    NSMutableArray<NSArray *> *_itemsInfo;
}

@end

@implementation ZFQTagLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)prepareLayout
{
    [super prepareLayout];
 
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    _preferMaxLayoutWidth = self.collectionView.frame.size.width;
    
    if (!_allItems) {
        _allItems = [[NSMutableArray alloc] initWithCapacity:itemCount];
    }
    [_allItems removeAllObjects];
    
    if (!_allLayoutAttributes) {
        _allLayoutAttributes = [[NSMutableArray alloc] initWithCapacity:itemCount];
    }
    [_allLayoutAttributes removeAllObjects];
    
    if (!_itemsInfo) {
        _itemsInfo = [[NSMutableArray alloc] init];
    }
    [_itemsInfo removeAllObjects];
    
    NSAssert(self.layoutDelegate != nil, @"You must set layoutDelegate and implement delegate method!");
    
    CGFloat currWidth = 0;
    NSInteger beginIndexOfCell = 0;//当前行开始的tag索引
    NSInteger preIndexOfCell = 0;  //前一行的开始的tag索引
    CGFloat itemMaxWidth = _preferMaxLayoutWidth - _edgeInsets.left - _edgeInsets.right;
    CGFloat indexOfRow = 0; //当前为第几行
    
    //1.计算 UICollectionViewLayoutAttributes
    for (NSInteger i = 0; i < itemCount; i++) {
        CGSize itemSize = [_layoutDelegate itemSizeAtRow:i];
        NSAssert(itemSize.width <= itemMaxWidth, @"The width of item is too large!");
        
        if (i == beginIndexOfCell) {
            currWidth = itemSize.width;
        } else {
            currWidth += (itemSize.width + _horizontalPadding);
        }
        
        if (currWidth < itemMaxWidth) {
            if (i == itemCount - 1) {
                //说明tags中的所有tagView的宽度和仍 < itemMaxWidth
                [_itemsInfo addObject:@[@(beginIndexOfCell),@(i - beginIndexOfCell + 1)]];
            }
        } else {
            //准备换行
            beginIndexOfCell = i;
            //添加前一行
            [_itemsInfo addObject:@[@(preIndexOfCell),@(beginIndexOfCell - preIndexOfCell)]];
            
            //如果恰好是最后一个需要换行，则无需计算，直接添加
            if (i == itemCount - 1) {
                [_itemsInfo addObject:@[@(i),@1]];
            }
            
            preIndexOfCell = beginIndexOfCell;
            indexOfRow++;
        }
        
        //得知道当前行数
        if (beginIndexOfCell == i) {
            currWidth = itemSize.width;
        }
        
        CGFloat itemOriginX = currWidth - itemSize.width;
        CGFloat itemOriginY = _edgeInsets.top + indexOfRow * (_itemHeight + _verticalPadding);
        CGRect itemFrame = CGRectMake(itemOriginX, itemOriginY, itemSize.width, _itemHeight);
        
        //设置item对应的layoutAttributes
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attr.frame = itemFrame;
        attr.indexPath = indexPath;
        
        [_allLayoutAttributes addObject:attr];
    }
    
    //拉伸每一行的item的宽度
    [_itemsInfo enumerateObjectsUsingBlock:^(NSArray * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self stretchItemWidthInRange:NSMakeRange([obj[0] integerValue], [obj[1] integerValue])];
    }];
    
    //设置contentsize
    CGFloat height = _itemsInfo.count * _itemHeight + (_itemsInfo.count - 1) * _verticalPadding + _edgeInsets.top + _edgeInsets.bottom;
    _contentSize = CGSizeMake(_preferMaxLayoutWidth, height);
}

//拉伸这一行的所有item的宽度
- (void)stretchItemWidthInRange:(NSRange)range
{
    NSInteger beginIndex = range.location;
    NSInteger length = range.length;
    
    CGRect originFrame = CGRectZero;
    CGFloat originWidth = 0;
    CGFloat originX = 0;
    CGFloat widthStretch = 0;
    CGFloat preTagViewMaxX = 0;
    
    //计算宽度和
    for (NSInteger i = 0; i < length; i++) {
        UICollectionViewLayoutAttributes *layoutAttr = _allLayoutAttributes[i + beginIndex];
        originWidth += layoutAttr.frame.size.width;
    }
    originWidth += (length - 1) * _horizontalPadding;
    
    //计算各个tagView的拉伸量
    CGFloat itemMaxWidth = _preferMaxLayoutWidth - _edgeInsets.left - _edgeInsets.right;
    widthStretch = (itemMaxWidth - originWidth)/length;
    for (NSInteger i = 0; i < length; i++) {
        //修改layoutAttributes的frame
        UICollectionViewLayoutAttributes *layoutAttr = _allLayoutAttributes[i + beginIndex];
        originFrame = layoutAttr.frame;
        originX = (i == 0) ? _edgeInsets.left : (preTagViewMaxX + _horizontalPadding);
        originFrame = CGRectMake(originX, originFrame.origin.y, originFrame.size.width + widthStretch, originFrame.size.height);
        layoutAttr.frame = originFrame;
        preTagViewMaxX = originFrame.origin.x + layoutAttr.size.width;
    }
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    [_allLayoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (CGRectIntersectsRect(rect, obj.frame)) {
            [mutableArray addObject:obj];
        }
    }];
    return mutableArray;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _allLayoutAttributes[indexPath.row];
}

- (CGSize)collectionViewContentSize
{
    return _contentSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    CGSize size = self.collectionView.frame.size;
    
    if (CGSizeEqualToSize(size, newBounds.size)) {
        return NO;
    } else {
        return YES;
    }
}

@end
