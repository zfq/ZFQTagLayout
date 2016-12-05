//
//  ZFQTagLayout.m
//  TagLayoutDemo
//
//  Created by _ on 16/11/21.
//  Copyright © 2016年 zhaofuqiang. All rights reserved.
//

#import "ZFQTagLayout.h"

typedef NS_ENUM(NSInteger,ZFQTagScrollDirection) {
    ZFQTagScrollDirectionUp,    //向上滚动
    ZFQTagScrollDirectionDown   //向下滚动
};

@interface ZFQTagLayout()
{
    CGSize _contentSize;
    
    NSMutableArray<UICollectionViewCell *> *_allItems;
    NSMutableArray<UICollectionViewLayoutAttributes *> *_allLayoutAttributes;
    NSMutableArray<NSArray *> *_itemsInfo;
    
    UILongPressGestureRecognizer *_longPressGesture;
    
    CGSize _offset;
    NSInteger _preAvailableRow;
    BOOL _isMoving; //判断是否正在滚动
    CADisplayLink *_displayLink;
    ZFQTagScrollDirection _scrollDirection;   //滚动方向 1：向上滚动   2：向下滚动
    CGFloat _scrollSpeed;
}

@property (nonatomic,strong) UIView *snapshotView;
@property (nonatomic,strong) NSIndexPath *originSelectedIndexPath;   //选中的row

@end

@implementation ZFQTagLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        _preAvailableRow = -1;
        _scrollSpeed = 200.f;
    }
    return self;
}

- (void)prepareLayout
{
    [super prepareLayout];
 
    [self calculateLayoutAttributes];
    [self addLongPressGestureIfNeeded];
}

- (void)calculateLayoutAttributes
{
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
    //获取所有可见的cell
    NSArray *array = _allLayoutAttributes;
//    NSArray *array = [self allVisibleAttributesInRect:rect];
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    [array enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (CGRectIntersectsRect(rect, obj.frame)) {
            [mutableArray addObject:obj];
//            if (_originSelectedIndexPath && obj.indexPath.row == _originSelectedIndexPath.row) {
//                obj.hidden = YES;
//            }
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

//处理横竖屏切换
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    CGSize size = self.collectionView.frame.size;
    
    if (CGSizeEqualToSize(size, newBounds.size)) {
        return NO;
    } else {
        return YES;
    }
}

- (NSArray<UICollectionViewLayoutAttributes *> *)allVisibleAttributesInRect:(CGRect)rect
{
    CGFloat minY = rect.origin.y;
    CGFloat maxY = CGRectGetMaxY(rect);
    
    //二分查找 minY、maxY分别落在哪一行
    NSInteger beginRow = [self binarySearchItem:minY isBegin:YES];
    NSInteger endRow = [self binarySearchItem:maxY isBegin:NO];

    if (!(beginRow >= 0 && endRow >= 0)) {
        NSLog(@"未找到指定行");
        return nil;
    }
    
    NSInteger beginIndex = [_itemsInfo[beginRow][0] integerValue];
    NSInteger endIndex = [_itemsInfo[endRow][0] integerValue] + [_itemsInfo[endRow][1] integerValue] - 1;
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:(endIndex - beginIndex + 1)];
    for (NSInteger i = beginIndex; i <= endIndex; i++) {
        [array addObject:(_allLayoutAttributes[i])];
    }
    
    return array;
}

#pragma mark - Private
- (NSInteger)binarySearchItem:(CGFloat)y isBegin:(BOOL)isBegin
{
    NSInteger left = 0,right = _itemsInfo.count - 1;
    
    while (left < right) {
        NSInteger mid = (left + right)/2;
        NSInteger index = [_itemsInfo[mid][0] integerValue];
        CGRect frame = _allLayoutAttributes[index].frame;
        
        if (isBegin) {
            if (y < frame.origin.y - _verticalPadding) {
                right = mid - 1;
            } else if (y > CGRectGetMaxY(frame)) {
                left = mid + 1;
            } else {
                return mid;
            }
        } else {
            if (y < frame.origin.y) {
                right = mid - 1;
            } else if (y > CGRectGetMaxY(frame) + _verticalPadding) {
                left = mid + 1;
            } else {
                return mid;
            }
        }
    }
    
    CGRect frame = _allLayoutAttributes[left].frame;
    if (isBegin) {
        if (y > CGRectGetMaxY(frame)) {
            return -1;
        } else {
            return left;
        }
    } else {
        if (y < frame.origin.y) {
            return -1;
        } else {
            return left;
        }
    }
}

//添加手势
- (void)addLongPressGestureIfNeeded
{
    if (!_longPressGesture) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
        [self.collectionView addGestureRecognizer:_longPressGesture];
    }
}

- (void)longPressGesture:(UILongPressGestureRecognizer *)gesture
{
    UICollectionView *tmpView = (UICollectionView *)gesture.view;
    CGPoint p = [gesture locationInView:tmpView];
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            [self ZFQBeginMovementFromPositon:p];
        } break;
        case UIGestureRecognizerStateChanged: {
            [self ZFQUpdateMovementTargetPosition:p];
        } break;
        case UIGestureRecognizerStateEnded: {
            [self ZFQEndMovementTargetPosition:p];
        }  break;
        default:
            [self ZFQCancelMovement];
            break;
    }
}

- (void)ZFQBeginMovementFromPositon:(CGPoint)p
{
    //为item创建截图，然后添加到collectionView上
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    UIView *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    _snapshotView = [cell zfqSnapshotImg];
    _snapshotView.frame = cell.frame;
    [self.collectionView addSubview:_snapshotView];
    
    //然后将选中的cell给隐藏掉
    cell.hidden = YES;
//    UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:_originSelectedIndexPath];
//    attr.hidden = YES;
    
    _originSelectedIndexPath = indexPath;
    
    CGPoint center = _snapshotView.center;
    _offset = CGSizeMake(center.x - p.x, center.y - p.y);
    _preAvailableRow = -1;
}

- (void)ZFQUpdateMovementTargetPosition:(CGPoint)p
{
    if (_isMoving) {
        return;
    }
    _snapshotView.center = CGPointMake(p.x + _offset.width, p.y + _offset.height);
    
    UICollectionView *collectionView = self.collectionView;
    
    //要移动的cell在底部，需要向上滚动
    BOOL needScroll = collectionView.contentOffset.y + collectionView.frame.size.height < _contentSize.height;
    if (_snapshotView.center.y >= collectionView.frame.size.height && needScroll) {
        //开始滚动collectionView
        NSLog(@"开始向上滚动");
        [self beginScrollWithDirection:ZFQTagScrollDirectionUp];
        return;
    }
    
    //要移动的cell在顶部，需要向下滚动
    if ((_snapshotView.center.y - collectionView.contentOffset.y)<= 0 && collectionView.contentOffset.y > 0) {
        //开始滚动collectionView
        NSLog(@"开始向下滚动");
        [self beginScrollWithDirection:ZFQTagScrollDirectionDown];
        return;
    }
    
    NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint:_snapshotView.center];
    if (!indexPath) return;
    if (indexPath.row == _preAvailableRow) return;
    if (_originSelectedIndexPath.row == indexPath.row) return;
    
    //1.更新数据源，就是把 _originSelectedIndexPath 删除掉，然后 将其插入到indexPath
    [self.layoutDelegate moveItemAtIndexPath:_originSelectedIndexPath toIndexPath:indexPath];
    //2.重新计算attr
    [self calculateLayoutAttributes];
    //3.更新UI：删除旧的item, 在新的地方insert一个item
    [collectionView moveItemAtIndexPath:_originSelectedIndexPath toIndexPath:indexPath];
    _originSelectedIndexPath = indexPath;
    _preAvailableRow = indexPath.row;
}

- (void)beginScrollWithDirection:(ZFQTagScrollDirection)scrollDirection
{
    if (_isMoving) {
        return;
    }
    _scrollDirection = scrollDirection;
    _isMoving = YES;
    //如果没有开启定时器，则开启定时器
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displaylinkAction:)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopScroll
{
    //停止滚动
    [_displayLink invalidate];
    _displayLink = nil;
    
    _isMoving = NO;
}

- (void)displaylinkAction:(CADisplayLink *)displayLink
{
    UICollectionView *collectionView = self.collectionView;
    //设置contentOffset
    CGFloat originOffsetY = collectionView.contentOffset.y;
    //判断滚动方向 是往上滚动还是往下滚动
    CGFloat delta = 0;
    if (_scrollDirection == ZFQTagScrollDirectionUp) {
        //向上滚动
        if (originOffsetY + collectionView.frame.size.height < _contentSize.height) {
            delta = _scrollSpeed * displayLink.duration;
        } else {
            [self stopScroll];
        }
    } else if (_scrollDirection == ZFQTagScrollDirectionDown) {
        //向下滚动
        if (originOffsetY > 0) {
            delta = -_scrollSpeed * displayLink.duration;
        } else {
            [self stopScroll];
        }
    }
    
    _snapshotView.center = CGPointMake(_snapshotView.center.x, _snapshotView.center.y + delta);
    collectionView.contentOffset = CGPointMake(0, originOffsetY + delta);
}

- (void)ZFQEndMovementTargetPosition:(CGPoint)p
{
    [self stopScroll];
    
    UICollectionView *collectionView = self.collectionView;
    NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint:p];
    if (!indexPath) {
        [self ZFQCancelMovement];
        return;
    }
    
    NSLog(@"stop!");
    //1.将截图放置到新的位置(动画效果)
    [UIView animateWithDuration:0.25 animations:^{
       _snapshotView.center = _allLayoutAttributes[indexPath.row].center;
    }];
    //2.在移动动画完成后就移除截图
    __weak typeof(self) weakSelf = self;
    [collectionView performBatchUpdates:^{

    } completion:^(BOOL finished) {
        //3.移除截图
        UIView *cell = [weakSelf.collectionView cellForItemAtIndexPath:weakSelf.originSelectedIndexPath];
        cell.hidden = NO;
//        UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:_originSelectedIndexPath];
//        attr.hidden = NO;
//        [weakSelf invalidateLayout];
        
        [weakSelf.snapshotView removeFromSuperview];
        weakSelf.snapshotView = nil;
        
        if ([weakSelf.layoutDelegate respondsToSelector:@selector(didMoveItemAtIndexPath:toIndexPath:)]) {
            [weakSelf.layoutDelegate didMoveItemAtIndexPath:_originSelectedIndexPath toIndexPath:indexPath];
        }
        _originSelectedIndexPath = nil;
    }];
}

- (void)ZFQCancelMovement
{
    [self stopScroll];
    
    UICollectionViewLayoutAttributes *attr = _allLayoutAttributes[_originSelectedIndexPath.row];
    UIView *cell = [self.collectionView cellForItemAtIndexPath:_originSelectedIndexPath];
    
    //1.将截图恢复到原始位置
    [UIView animateWithDuration:0.25 animations:^{
        _snapshotView.center = attr.center;
    } completion:^(BOOL finished) {
        if (finished) {
            //2.设置hidden为NO
            cell.hidden = NO;
            //3.移除截图
            [_snapshotView removeFromSuperview];
            _snapshotView = nil;
            _preAvailableRow = -1;
        }
    }];
}

@end

@implementation UIView(ZFQTagLayout)

- (UIView *)zfqSnapshotImg
{
    if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)]) {
        return [self snapshotViewAfterScreenUpdates:YES];
    } else {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, [UIScreen mainScreen].scale);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return [[UIImageView alloc] initWithImage:img];
    }
}

@end
