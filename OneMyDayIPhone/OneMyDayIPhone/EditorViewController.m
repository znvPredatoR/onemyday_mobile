//
//  EditorViewController.m
//  OneMyDayIPhone
//
//  Created by dmitry.solomadin on 17.04.13.
//  Copyright (c) 2013 Admin. All rights reserved.
//

#import "EditorViewController.h"
#import "EditorStore.h"
#import "EditorItemView.h"
#import "ViewWithAttributes.h"
#import "AddTextViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface EditorViewController ()
{
    UIScrollView *scrollView;
}

- (void)exitEditingMode;

@end

@implementation EditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // add navigation
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain
                                                                    target:self action:@selector(dismissSelf:)];
    UIBarButtonItem *publishButton = [[UIBarButtonItem alloc] initWithTitle:@"Publish" style:UIBarButtonItemStylePlain
                                                                     target:self action:@selector(publishStory:)];
    [publishButton setTintColor:[UIColor colorWithRed:0.08 green:0.78 blue:0.08 alpha:0.5]];
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = publishButton;
    
    // add scroll view
    scrollView = [[UIScrollView alloc] initWithFrame: CGRectMake(0, 0, 320, self.view.bounds.size.height - 95)];
    [[self view] addSubview:scrollView];
    
    // add previously saved images&texts if any
    NSMutableDictionary *keyToItem = [[EditorStore get] loadAllItems];
    for (NSString *key in keyToItem) {
        NSObject *item = [keyToItem objectForKey:key];
        if ([item isKindOfClass:[UIImage class]]) {
            [self addPhotoToTheView:(UIImage *)item withKey:key];
        } else if ([item isKindOfClass:[NSString class]]) {
            [self addTextToTheView:(NSString *)item withKey:key];
        }
    }
    
    // add bottom bar
    [self addBottomButtonWithTitle:@"Photo" frame:CGRectMake(0.1, 0.0, 108, 50) action:@selector(addPhoto:)];
    [self addBottomButtonWithTitle:@"Library" frame:CGRectMake(107.0, 0.0, 108, 50) action:@selector(addPhotoFromLib:)];
    [self addBottomButtonWithTitle:@"Text" frame:CGRectMake(214.0, 0.0, 107, 50) action:@selector(addText:)];
    
    // other
    [[self view] setBackgroundColor:[UIColor whiteColor]];
}

- (UIButton *)addBottomButtonWithTitle:(NSString *)title frame:(CGRect)frame action:(SEL)selector {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *buttonBG = [[UIImage imageNamed:@"editorbar_button"] stretchableImageWithLeftCapWidth:1 topCapHeight:0];
    UIImage *buttonBGSelected = [[UIImage imageNamed:@"editorbar_button_highlight"] stretchableImageWithLeftCapWidth:1 topCapHeight:0];
    [button setBackgroundImage:buttonBG forState:UIControlStateNormal];
    [button setBackgroundImage:buttonBGSelected forState:UIControlStateHighlighted];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];

    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin
    | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    
    frame.origin.y = self.view.bounds.size.height - frame.size.height;
    button.frame = frame;
    
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    return button;
}

- (void)addPhoto:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    } else {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    
    [imagePicker setDelegate:self];
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)addText:(id)sender
{
    AddTextViewController *textVC = [[AddTextViewController alloc] init];
    [textVC setController:self];
    UINavigationController *textVCNav = [[UINavigationController alloc] initWithRootViewController:textVC];
    [self presentViewController:textVCNav animated:YES completion:nil];
}

- (void)addPhotoFromLib:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [imagePicker setDelegate:self];
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#define DELETE_BUTTON_TAG 666

- (void)addPhotoToTheView:(UIImage *)photo withKey:(NSString *)key
{
    EditorItemView *itemView = [[EditorItemView alloc] initWithFrame:CGRectMake(10, [self getCurrentScrollHeight], 300, 300)
                                                             andType:photoItemType];
    
    // add photo
    UIImageView *photoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    [photoView setImage:photo];
    [itemView addSubview:photoView];
    
    // add photo hidden button
    UIButton *imageBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    [itemView addSubview:imageBtn];
    [itemView bringSubviewToFront:imageBtn];
    
    // create long press gesture recognizer
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(enterEditingMode:)];
    longPress.minimumPressDuration = 0.75; //seconds
    [imageBtn addGestureRecognizer:longPress];
    
    // add photo delete button
    [self addDeleteButtonToView:itemView withKey:key];
    
    [scrollView addSubview:itemView];
    [scrollView setContentSize:(CGSizeMake(320, [self getCurrentScrollHeight]))];
}

- (void)addTextToTheView:(NSString *)text withKey:(NSString *)key
{
    NSLog(@"here!");
    EditorItemView *itemView = [[EditorItemView alloc] initWithFrame:CGRectMake(10, [self getCurrentScrollHeight], 300, 300)
                                                             andType:textItemType];
    
    // add text
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    textView.layer.cornerRadius = 5.0;
    textView.clipsToBounds = NO;
    textView.layer.borderWidth = 1.0f;
    textView.layer.borderColor = [[UIColor colorWithRed:0.65 green:0.65 blue:0.65 alpha:0.5] CGColor];
    [textView setText:text];
    [textView setBackgroundColor:[UIColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:0.5]];
    [textView setFont:[UIFont systemFontOfSize:17]];
    [textView setEditable:NO];
    [textView sizeToFit];
    [itemView addSubview:textView];
    [itemView setFrame:CGRectMake(itemView.frame.origin.x, itemView.frame.origin.y,
                                  itemView.frame.size.width, textView.frame.size.height)];
    
    // add text hidden button
    UIButton *textBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 300, textView.frame.size.height)];
    [itemView addSubview:textBtn];
    [itemView bringSubviewToFront:textBtn];
    
    // create long press gesture recognizer
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(enterEditingMode:)];
    longPress.minimumPressDuration = 0.75; //seconds
    [textBtn addGestureRecognizer:longPress];
    
    // add photo delete button
    [self addDeleteButtonToView:itemView withKey:key];
    
    [scrollView addSubview:itemView];
    [scrollView setContentSize:(CGSizeMake(320, [self getCurrentScrollHeight]))];
}

- (void)addDeleteButtonToView:(UIView *)view withKey:(NSString *)key
{
    ViewWithAttributes *deleteBtnWrap = [[ViewWithAttributes alloc] initWithFrame:CGRectMake(275, -5, 32, 32)];
    [deleteBtnWrap addAttribute:key forKey:@"item_to_delete"];
    UIButton *deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [deleteBtn setBackgroundImage:[UIImage imageNamed:@"image_remove"] forState:UIControlStateNormal];
    [deleteBtn setHidden:YES];
    [deleteBtn addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
    [deleteBtnWrap setTag:DELETE_BUTTON_TAG];
    [deleteBtnWrap addSubview:deleteBtn];
    [view addSubview:deleteBtnWrap];
}

- (void)deleteItem:(UIView *)sender
{
    ViewWithAttributes *buttonWrap = (ViewWithAttributes *)[sender superview];
    UIView *itemView = [buttonWrap superview];
    EditorViewController *this = self;
    [UIView animateWithDuration:0.2 animations:^{itemView.alpha = 0.0;}
                     completion:^(BOOL finished) {
                         [itemView removeFromSuperview];
                         [[EditorStore get] deleteImageWithKey:[buttonWrap getAttributeForKey:@"item_to_delete"]];
                         
                         for (UIView *view in [scrollView subviews]) {
                             if ([view isKindOfClass:[EditorItemView class]] &&
                                    view.frame.origin.y > itemView.frame.origin.y) {
                                 [UIView beginAnimations:@"searchGrowUp" context:nil];
                                 [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                                 [UIView setAnimationDuration:0.3f];
                            
                                 view.frame = CGRectOffset(view.frame, 0, -(itemView.frame.size.height + 10));
                                 
                                 [UIView commitAnimations];
                             }
                         }
                         
                         [this exitEditingMode];
                     }];
}

- (void)enterEditingMode:(id)sender
{
    for (UIView *view in [scrollView subviews]) {
        if ([view isKindOfClass:[EditorItemView class]]) {
            [[[[view viewWithTag:DELETE_BUTTON_TAG] subviews] objectAtIndex:0] setHidden:NO];
        }
    }
}

- (void)exitEditingMode
{
    for (UIView *view in [scrollView subviews]) {
        if ([view isKindOfClass:[EditorItemView class]]) {
            [[[[view viewWithTag:DELETE_BUTTON_TAG] subviews] objectAtIndex:0] setHidden:YES];
        }
    }
}

- (float)getCurrentScrollHeight
{
    float height = 0;
    int count = 0;
    for (UIView *view in [scrollView subviews]) {
        if ([view isKindOfClass:[EditorItemView class]]) {
            height += view.frame.size.height;
            count++;
        }
    }
    return height + count * 10 + 10;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSString *key = [[EditorStore get] saveImage:image];
    [self addPhotoToTheView:image withKey: key];
}

- (void)dismissSelf:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
