//
//  MyCollectionViewCell.m
//  TagLayoutDemo
//
//  Created by _ on 11/27/16.
//  Copyright © 2016 zhaofuqiang. All rights reserved.
//

#import "MyCollectionViewCell.h"

@implementation MyCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _textLabel = [[UILabel alloc] init];
//        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.backgroundColor = [UIColor orangeColor];
        [self.contentView addSubview:_textLabel];
        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary *views = @{@"label":_textLabel};
        NSArray *hCons = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[label]-0-|" options:0 metrics:nil views:views];
        NSArray *vCons = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[label]-0-|" options:0 metrics:nil views:views];
        [self.contentView addConstraints:hCons];
        [self.contentView addConstraints:vCons];
        
        self.backgroundColor = [UIColor brownColor];
    }
    return self;
}

@end
