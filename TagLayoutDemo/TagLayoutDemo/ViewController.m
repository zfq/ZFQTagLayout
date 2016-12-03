//
//  ViewController.m
//  TagLayoutDemo
//
//  Created by _ on 16/11/21.
//  Copyright © 2016年 zhaofuqiang. All rights reserved.
//

#import "ViewController.h"
#import "ZFQTagLayout.h"
#import "MyCollectionViewCell.h"

@interface ViewController () <UICollectionViewDataSource,UICollectionViewDelegate,ZFQTagLayoutDelegate>
{
    NSMutableArray *_testArray;
    UILongPressGestureRecognizer *_longPressGesture;
    
    UILabel *_tmpLabel;
}
@property (nonatomic,strong) UICollectionView *collectionView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tmpLabel = [[UILabel alloc] init];
    
    CGFloat x = 20;
    CGFloat layoutWidth = [UIScreen mainScreen].bounds.size.width - 2 * x;
    
    ZFQTagLayout *layout = [[ZFQTagLayout alloc] init];
    layout.edgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    layout.horizontalPadding = 5;
    layout.verticalPadding = 5;
    layout.itemHeight = 30;
    layout.preferMaxLayoutWidth = layoutWidth;
    layout.layoutDelegate = self;
    
    UICollectionView *myCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    myCollectionView.dataSource = self;
    myCollectionView.delegate = self;
    myCollectionView.backgroundColor = [UIColor lightGrayColor];
    myCollectionView.allowsSelection = YES;
    myCollectionView.showsVerticalScrollIndicator = NO;
    myCollectionView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:myCollectionView];
    self.collectionView = myCollectionView;
    
    myCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = @{@"collectionView":myCollectionView};
    NSDictionary *metrics = @{@"width":@(layoutWidth),@"margin":@(x),@"height":@400};
    NSArray *hCons = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-margin-[collectionView]-margin-|" options:0 metrics:metrics views:views];
    NSArray *vCons = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[collectionView]-400-|" options:0 metrics:metrics views:views];
    [self.view addConstraints:hCons];
    [self.view addConstraints:vCons];
    
    [myCollectionView registerClass:[MyCollectionViewCell class] forCellWithReuseIdentifier:@"a"];
    
    //load dataSource
    NSString *path = [[NSBundle mainBundle] pathForResource:@"tags" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *tmpArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    _testArray = [[NSMutableArray alloc] initWithArray:tmpArray];
    
    //add long gesture to UICollectionView
//    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
//    [myCollectionView addGestureRecognizer:_longPressGesture];
}

- (void)longPressGesture:(UIGestureRecognizer *)gesture
{
    UICollectionView *tmpView = (UICollectionView *)gesture.view;
    CGPoint p = [gesture locationInView:tmpView];
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *selectedIndexPath = [tmpView indexPathForItemAtPoint:p];
            [tmpView beginInteractiveMovementForItemAtIndexPath:selectedIndexPath];
        } break;
        case UIGestureRecognizerStateChanged: {
            [tmpView updateInteractiveMovementTargetPosition:p];
        } break;
        case UIGestureRecognizerStateEnded: {
            [tmpView endInteractiveMovement];
        }  break;
        default:
            [tmpView cancelInteractiveMovement];
            break;
    }
}

#pragma mark - ZFQTagLayoutDelegate
- (CGSize)itemSizeAtRow:(NSUInteger)row
{
    NSDictionary *dict = _testArray[row];
    NSString *name = dict[@"name"];
    
    //Do not use follow method, it's not accurate
//    NSDictionary *attr = @{
//                           NSForegroundColorAttributeName:[UIColor blackColor],
//                           NSFontAttributeName:[UIFont systemFontOfSize:17]
//                           };
//    CGSize size = [name sizeWithAttributes:attr];
    
    _tmpLabel.text = name;
    [_tmpLabel sizeToFit];
    return _tmpLabel.frame.size;
}

- (void)moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    id source = _testArray[fromIndexPath.row];
    [_testArray removeObjectAtIndex:fromIndexPath.row];
    [_testArray insertObject:source atIndex:toIndexPath.row];
}

- (void)didMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
//    NSLog(@"完成排序");
//    for (NSString *str in _testArray) {
//        NSLog(@"%@",str);
//    }
}

#pragma mark - UICollectionViewDatasource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _testArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MyCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"a" forIndexPath:indexPath];
    NSDictionary *dict = _testArray[indexPath.row];
    NSString *name = dict[@"name"];
    cell.textLabel.text = name;
    return cell;
}

//- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath
//{
//    [_testArray exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
//}


#pragma mark - UICollectionViewDelegate
//- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    return YES;
//}
//
//- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    
//}
//
//- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
//{
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)tapBtnAction:(id)sender {
    [self.collectionView reloadData];
}
@end
