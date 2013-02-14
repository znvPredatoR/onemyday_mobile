//
//  CloseupViewController.h
//  YellowJacket
//
//  Created by Wayne Cochran on 7/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@interface CloseupViewController : UIViewController {
    IBOutlet AsyncImageView *myImageView;
    NSURL *myURL;
}

@property (nonatomic, strong) AsyncImageView *myImageView;
@property (nonatomic, strong) NSURL *myURL;

@end
