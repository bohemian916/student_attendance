//
//  settingViewController.m
//  student_attend
//
//  Created by 石田陽太 on 2015/10/11.
//  Copyright (c) 2015年 yota. All rights reserved.
//

#import "settingViewController.h"
#import "ViewController.h"

@implementation settingViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"set"]) {
        ViewController *vcntl = [segue destinationViewController];
        vcntl.ip = self.textField.text;
        vcntl.api = self.apiTextField.text;
    }
}

@end
