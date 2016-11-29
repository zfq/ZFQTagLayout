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
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CGFloat x = 20;
    CGFloat layoutWidth = [UIScreen mainScreen].bounds.size.width - 2 * x;
    
    ZFQTagLayout *layout = [[ZFQTagLayout alloc] init];
    layout.edgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    layout.horizontalPadding = 5;
    layout.verticalPadding = 5;
    layout.itemHeight = 30;
    layout.preferMaxLayoutWidth = layoutWidth;
    layout.layoutDelegate = self;
    UICollectionView *myCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(x, 20, layoutWidth, 400) collectionViewLayout:layout];
    myCollectionView.dataSource = self;
    myCollectionView.delegate = self;
    myCollectionView.backgroundColor = [UIColor lightGrayColor];
    myCollectionView.allowsSelection = YES;
    [self.view addSubview:myCollectionView];
    [myCollectionView registerClass:[MyCollectionViewCell class] forCellWithReuseIdentifier:@"a"];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"tags" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *tmpArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    _testArray = [[NSMutableArray alloc] initWithArray:tmpArray];
}

#pragma mark - ZFQTagLayoutDelegate
- (CGSize)itemSizeAtRow:(NSUInteger)row
{
    NSDictionary *dict = _testArray[row];
    NSString *name = dict[@"name"];
    NSDictionary *attr = @{
                           NSForegroundColorAttributeName:[UIColor blackColor],
                           NSFontAttributeName:[UIFont systemFontOfSize:17]
                           };
    CGSize size = [name sizeWithAttributes:attr];
    return size;
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

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath
{
    [_testArray exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
}

#pragma mark - UICollectionViewDelegate
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView beginInteractiveMovementForItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
//    updateInteractiveMovementTargetPosition
    [collectionView endInteractiveMovement];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
