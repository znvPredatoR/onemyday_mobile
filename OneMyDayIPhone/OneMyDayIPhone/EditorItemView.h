//
//  EditorItemView.h
//  Onemyday
//
//  Created by dmitry.solomadin on 29.04.13.
//  Copyright (c) 2013 Admin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditorStore.h"

@interface EditorItemView : UIView

- (id)initWithFrame:(CGRect)frame andType:(ItemType)_type;

@property (nonatomic) ItemType *type;

@end
