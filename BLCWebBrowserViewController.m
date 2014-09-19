//
//  BLCWebBrowserViewController.m
//  BlocBrowser
//
//  Created by Brian Doore on 9/8/14.
//  Copyright (c) 2014 Brian Doore. All rights reserved.
//

#import "BLCWebBrowserViewController.h"
#import "BLCAwesomeFloatingToolbar.h"

#define kBLCWebBrowserBackString NSLocalizedString(@"Back", @"Back command")
#define kBLCWebBrowserForwardString NSLocalizedString(@"Forward", @"Forward command")
#define kBLCWebBrowserStopString NSLocalizedString(@"Stop", @"Stop command")
#define kBLCWebBrowserRefreshString NSLocalizedString(@"Refresh", @"Reload command")

@interface BLCWebBrowserViewController () <UIWebViewDelegate, UITextFieldDelegate, BLCAwesomeFloatingToolbarDelegate>

@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) BLCAwesomeFloatingToolbar *awesomeToolbar;
@property (nonatomic, assign) NSUInteger frameCount;
@property (nonatomic, assign) CGFloat lastScale;


@end


@implementation BLCWebBrowserViewController

#pragma mark -UIViewController

- (void)loadView {
    
    UIView *mainView = [UIView new];
    
    self.webview = [[UIWebView alloc] init];
    self.webview.delegate = self;
    
    self.textField = [[UITextField alloc] init];
    self.textField.keyboardType = UIKeyboardTypeWebSearch;
    self.textField.returnKeyType = UIReturnKeyGo;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"Website URL or Google search", @"Placeholder text for web browser URL field");
    self.textField.backgroundColor = [UIColor colorWithWhite:220/255.0f alpha:1];
    self.textField.delegate = self;
    
    self.awesomeToolbar = [[BLCAwesomeFloatingToolbar alloc] initWithFourTitles:@[kBLCWebBrowserBackString, kBLCWebBrowserForwardString, kBLCWebBrowserStopString, kBLCWebBrowserRefreshString]];
    self.awesomeToolbar.delegate = self;
    
    for (UIView *viewToAdd in @[self.webview, self.textField, self.awesomeToolbar])
    {

        [mainView addSubview:viewToAdd];
    
    }
    
    self.view = mainView;
    
    
    
    
    //self.awesomeToolbar.userInteractionEnabled = false;
}


- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    static CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight;
    
    self.textField.frame=CGRectMake(0,0, width, itemHeight);
    self.webview.frame=CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    
    
//    CGFloat width = CGRectGetWidth(self.view.bounds);
//    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - 50;
    
    NSLog(@" %f, %f, %f, %f", self.awesomeToolbar.frame.origin.x, self.awesomeToolbar.frame.origin.y, self.awesomeToolbar.frame.size.height, self.awesomeToolbar.frame.size.width);
    
    
    if (self.awesomeToolbar.frame.size.height==0 && self.awesomeToolbar.frame.size.width ==0) {
        self.awesomeToolbar.frame = CGRectMake((width/2 - 140), browserHeight-40, 280, 60);
    }

    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    _lastScale = 1;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    // Do any additional setup after loading the view.
}

- (void) resetWebView
{
    [self.webview removeFromSuperview];
    
    UIWebView *newWebView = [[UIWebView alloc] init];
    newWebView.delegate = self;
    [self.view addSubview:newWebView];
    
    self.webview = newWebView;
    
    self.textField.text = nil;
    [self updateButtonsAndTitle];
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSString *URLString = textField.text;
    
    NSLog(@"%i",[URLString rangeOfString:@" "].length);
    
    NSURL *URL;
    
    if ([URLString rangeOfString:@" "].length > 0)
    {
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://google.com/search?q=%@", [URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        //URLString = [NSString stringWithFormat:@"http://google.com/search?q=%@", URLString];
        NSLog(@"%@",URL.absoluteString);

    }
    else
    {
        URL = [NSURL URLWithString:URLString];
        NSLog(@"%@",URL.absoluteString);
    }
    
    if (!URL.scheme) {
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", URLString]];
        NSLog(@"%@",URL.absoluteString);
    }

    if (URL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        [self.webview loadRequest:request];
    }
    
    return NO;
}

#pragma mark - UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (error.code != -999) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
    // was a bug here on the website. if you get an error it leaves the spinny wheel going because the frame count is subtracted after the update.
    
    self.frameCount--;
    [self updateButtonsAndTitle];
    
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.frameCount++;
    [self updateButtonsAndTitle];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.frameCount--;
    [self updateButtonsAndTitle];
}
#pragma mark - Misc

- (void) updateButtonsAndTitle
{
    NSString *webpageTitle = [self.webview stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    if (webpageTitle)
    {
        self.title = webpageTitle;
    } else {
        self.title = self.webview.request.URL.absoluteString;
    }
    
    if (self.frameCount > 0)
    {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    
    [self.awesomeToolbar setEnabled:[self.webview canGoBack] forButtonWithTitle:kBLCWebBrowserBackString];
    [self.awesomeToolbar setEnabled:[self.webview canGoForward] forButtonWithTitle:kBLCWebBrowserForwardString];
    [self.awesomeToolbar setEnabled:self.frameCount > 0 forButtonWithTitle:kBLCWebBrowserStopString];
    [self.awesomeToolbar setEnabled:self.webview.request.URL && self.frameCount == 0 forButtonWithTitle:kBLCWebBrowserRefreshString];
    
}

#pragma mark - BLCAwesomeFloatingToolbarDelegate

- (void) floatingToolbar:(BLCAwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title {
    if ([title isEqual:kBLCWebBrowserBackString]) {
        [self.webview goBack];
    } else if ([title isEqual:kBLCWebBrowserForwardString]) {
        [self.webview goForward];
    } else if ([title isEqual:kBLCWebBrowserStopString]) {
        [self.webview stopLoading];
    } else if ([title isEqual:kBLCWebBrowserRefreshString]) {
        [self.webview reload];
    }
}

- (void) floatingToolbar:(BLCAwesomeFloatingToolbar *)toolbar didTryToPanWithOffset:(CGPoint)offset {
    CGPoint startingPoint = toolbar.frame.origin;
    CGPoint newPoint = CGPointMake(startingPoint.x + offset.x, startingPoint.y + offset.y);
    
    CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, CGRectGetWidth(toolbar.frame), CGRectGetHeight(toolbar.frame));
    
    if (CGRectContainsRect(self.view.bounds, potentialNewFrame)) {
        toolbar.frame = potentialNewFrame;
    }
}

- (void) floatingToolbar:(BLCAwesomeFloatingToolbar *)toolbar didTryToScaleWithScalar:(CGFloat)scale {
    
    CGPoint startingPoint = toolbar.frame.origin;
    CGPoint newPoint = CGPointMake(startingPoint.x , startingPoint.y);
    
    CGFloat newScale = 1 -  (_lastScale - scale);
    
    CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, (CGRectGetWidth(toolbar.frame)*newScale), (CGRectGetHeight(toolbar.frame)*newScale));
    
    if (CGRectGetWidth(potentialNewFrame)<= 280 && CGRectGetWidth(potentialNewFrame)>= 150 && CGRectContainsRect(self.view.bounds, potentialNewFrame))
        self.awesomeToolbar.frame = potentialNewFrame;
    
    NSLog(@"New scalar: %f", scale);
    _lastScale = scale;
//    NSLog(@"New rect: %@", NSStringFromRect(potentialNewFrame));

    
    //if (CGRectContainsRect(self.view.bounds, potentialNewFrame))
    //{
    //self.awesomeToolbar.frame = potentialNewFrame;
    //}
    
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
