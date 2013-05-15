//
//  NewMasterViewController.m
//  OneMyDayIPhone
//
//  Created by dmitry.solomadin on 09.04.13.
//  Copyright (c) 2013 Admin. All rights reserved.
//

#import "HomeViewController.h"
#import "Request.h"
#import "Story.h"
#import "ThumbStoryView.h"
#import "ShowStoryViewController.h"
#import "StoryStore.h"
#import "UserStore.h"

@interface HomeViewController ()
{
    NSMutableArray * stories;
    UIActivityIndicatorView *topIndicator;
    UIActivityIndicatorView *bottomIndicator;
    bool *oldStoriesLoading;
}
@end

@implementation HomeViewController
@synthesize scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    oldStoriesLoading = false;
}

- (void)storyTap:(NSNumber *)storyId
{
    Story *story = [[StoryStore get] findById:[storyId intValue]];
    ShowStoryViewController *showStoryViewController = [[ShowStoryViewController alloc] initWithStory:story];
    [[self navigationController] pushViewController:showStoryViewController animated:YES];
}

- (void)viewDidLoad
{     
    [super viewDidLoad];    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:)
                                                 name:@"AsyncImageLoadDidFail" object:nil];
    
    scrollView = [[UIScrollView alloc] initWithFrame: CGRectZero];
    [[self view] addSubview:scrollView];
    [self.scrollView setDelegate:self];
    
    if (_refreshHeaderView == nil) {
		
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - scrollView.bounds.size.height, scrollView.frame.size.width, scrollView.bounds.size.height)];
		view.delegate = self;
		[scrollView addSubview:view];
		_refreshHeaderView = view;		
	}
      
    oldFeedHeight = 10.0;
    
    stories = [[StoryStore get] loadStoriesFromDisk];
    __block NSMutableArray *oldStories = stories;
    [[UserStore get] loadUsersFromDisk];    
    
    for (int i = 0; i < [oldStories count]; i++) {
        Story *story = [oldStories objectAtIndex:i];
        CGRect frame = CGRectMake(10, oldFeedHeight, 300, 300);
        ThumbStoryView *thumbStoryView = [[ThumbStoryView alloc] initWithFrame:frame story:story];
        thumbStoryView.controller = self;
                
        [scrollView addSubview:thumbStoryView];
        oldFeedHeight += 355;        
    }       
        
    [scrollView setContentSize:(CGSizeMake(320, oldFeedHeight))];
            
    NSLog(@"oldStories count is: %d", [oldStories count]);
        
    NSLog(@"oldUser count is: %d", [[[UserStore get] getUsers] count]);
    
    topIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    topIndicator.frame = CGRectMake(10, 45, 100, 100);
    topIndicator.center = CGPointMake(160, 15);
    topIndicator.hidesWhenStopped = YES;
    [scrollView addSubview: topIndicator];
    [topIndicator bringSubviewToFront: scrollView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [topIndicator startAnimating];
    
    [self refreshView: nil];
    
    // Add this instance of TestClass as an observer of the TestNotification.
    // We tell the notification center to inform us of "TestNotification"
    // notifications using the receiveTestNotification: selector. By
    // specifying object:nil, we tell the notification center that we are not
    // interested in who posted the notification. If you provided an actual
    // object rather than nil, the notification center will only notify you
    // when the notification was posted by that particular object.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshView:)
                                             name:@"refreshViewNotification"
                                             object:nil];
	
}

- (void)refreshView:(NSNotification *) notification
{
    /*if ([[notification name] isEqualToString:@"refreshViewNotification"])
                        NSLog (@"Successfully received the test notification!");*/	
    
    // how we stop refresh from freezing the main UI thread
    dispatch_queue_t downloadQueue = dispatch_queue_create("downloader", NULL);
    dispatch_async(downloadQueue, ^{
        
        // do our long running process here
        [NSThread sleepForTimeInterval:3];
        long storyId = 0;       
        
        if(stories != NULL && [stories count] > 0) storyId = [[stories objectAtIndex:0] storyId];
        
        NSMutableArray *newStories = [[StoryStore get] requestStoriesIncludePhotos:YES includeUser:YES newStories: true lastId: storyId withLimit: 11];
        
        // do any UI stuff on the main UI thread
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"newStories count is: %d", [newStories count]);
            
            NSLog(@"user count is: %d", [[[UserStore get] getUsers] count]);
            
            if(newStories != NULL && [newStories count] > 0)
            {
                NSMutableArray *oldStories = stories;
                stories = newStories;
                CGFloat currentFeedHeight = 10.0;
                //Story *oldStory = nil;
                //if(oldStories != NULL && [oldStories count] > 0)oldStory = [oldStories objectAtIndex: 0];
                int storiesCount = [stories count];                              
               
                if(storiesCount == 11 && [[stories objectAtIndex: 10] storyId] != storyId){
                    int oldSubViewsCount = [[scrollView subviews] count] - 1;
                    for (int i = 0; i < oldSubViewsCount; i++) {
                       
                        //if([[[scrollView subviews] objectAtIndex:j] isKindOfClass:[ThumbStoryView class]]){                           
                           
                            [[[scrollView subviews] objectAtIndex:1] removeFromSuperview];                           
                            
                        //} else j++;
                        
                    }
                    oldFeedHeight = 0;                 
                }
                
                for (int i = 0; i < storiesCount; i++) {
                    
                    Story *story = [stories objectAtIndex: i];                                      
                    
                    CGRect frame = CGRectMake(10, currentFeedHeight, 300, 300);
                    ThumbStoryView *thumbStoryView = [[ThumbStoryView alloc] initWithFrame:frame story:story];
                    thumbStoryView.controller = self;
                    [scrollView insertSubview: thumbStoryView atIndex: 0];
                    currentFeedHeight  += 355;
                }
                NSLog(@"[[scrollView subviews] count] %d",[[scrollView subviews] count]);
                
                
                    
               if(storiesCount != 11 || (storiesCount != 11 && [[stories objectAtIndex: 10] storyId] != storyId)){
                   int start = storiesCount + 1;
                    for (int i = start, j = 0; i < [[scrollView subviews] count]; i++) {
                    
                        if([[[scrollView subviews] objectAtIndex:i] isKindOfClass:[ThumbStoryView class]]){                            
                            
                            ThumbStoryView *tSV = [[scrollView subviews] objectAtIndex:i];
                            CGRect rect = tSV.frame;
                            rect.origin = CGPointMake(tSV.frame.origin.x, tSV.frame.origin.y + currentFeedHeight);
                            tSV.frame = rect;
                            [stories addObject: [oldStories objectAtIndex: j]];
                            j++;
                        }
                    }
                }
                //  update the last update date
                [_refreshHeaderView refreshLastUpdatedDate];
                oldFeedHeight += currentFeedHeight;
                [scrollView setContentSize: CGSizeMake(320, oldFeedHeight)];
                
            }
            
            NSLog(@"stories count is: %d", [stories count]);
            [[StoryStore get] setStories:stories];
            [topIndicator stopAnimating];
            
            //[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
        });
     });
    
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	_reloading = YES;
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.scrollView];
	
}


#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)sView{
	
	[_refreshHeaderView egoRefreshScrollViewDidScroll:sView];
    
    if(!oldStoriesLoading && (oldFeedHeight - scrollView.contentOffset.y) <= 500){
        oldStoriesLoading = true;
        //NSLog(@"y %f", scrollView.contentOffset.y);
        bottomIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        bottomIndicator.frame = CGRectMake(10, 45, 100, 100);
        bottomIndicator.center = CGPointMake(160, oldFeedHeight + 20);
        bottomIndicator.hidesWhenStopped = YES;
        [sView addSubview: bottomIndicator];
        [bottomIndicator bringSubviewToFront: sView];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [sView setContentSize: CGSizeMake(320, oldFeedHeight + 355)];
        [bottomIndicator startAnimating];
        
        [self getOldStories];
    }    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)sView willDecelerate:(BOOL)decelerate{
	
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:sView];
	
}


#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}

- (void)getOldStories{
	
	// how we stop refresh from freezing the main UI thread
    dispatch_queue_t downloadQueue = dispatch_queue_create("downloader", NULL);
    dispatch_async(downloadQueue, ^{
        
        // do our long running process here
        //[NSThread sleepForTimeInterval:3];
        long storyId = 0;
        
        if(stories != NULL && [stories count] > 0) storyId = [[stories objectAtIndex:([stories count] - 1)] storyId];
        
        NSMutableArray *newStories = [[StoryStore get] requestStoriesIncludePhotos:YES includeUser:YES newStories: false lastId: storyId withLimit: 10];
        
        // do any UI stuff on the main UI thread
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"newStories count is: %d", [newStories count]);
            
            NSLog(@"user count is: %d", [[[UserStore get] getUsers] count]);
            
            [bottomIndicator stopAnimating];
            
            [[[scrollView subviews] objectAtIndex:[[scrollView subviews] count]-1] removeFromSuperview];            
            
            if(newStories != NULL && [newStories count] > 0){                
                
                for (int i = 0; i < [newStories count]; i++) {
                    
                    Story *story = [newStories objectAtIndex: i];
                    
                    CGRect frame = CGRectMake(10, oldFeedHeight, 300, 300);
                    ThumbStoryView *thumbStoryView = [[ThumbStoryView alloc] initWithFrame:frame story:story];
                    thumbStoryView.controller = self;
                    [scrollView addSubview: thumbStoryView];
                    oldFeedHeight  += 355;
                    
                    [stories addObject:story];
                }                                              
            }
            
            [scrollView setContentSize: CGSizeMake(320, oldFeedHeight)];
            
            NSLog(@"stories count is: %d", [stories count]);
            [[StoryStore get] setStories:stories];
            
            
            oldStoriesLoading = false;
            
            //[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
        });
    });
	
}


@end

