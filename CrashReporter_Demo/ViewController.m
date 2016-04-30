//
//  ViewController.m
//  CrashReporter_Demo
//
//  Created by Victor John on 4/27/16.
//  Copyright © 2016 com.xiaoruigege. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //The project will be crashed by the following code
    int a = 9 ;
    int b = 0;
    int c = a / b;
    
}
@end
