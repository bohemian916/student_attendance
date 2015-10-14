//
//  ViewController.m
//  student_attend
//
//  Created by 石田陽太 on 2015/10/11.
//  Copyright (c) 2015年 yota. All rights reserved.
//

#import "ViewController.h"
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/videoio/cap_ios.h>
#endif

//#import <opencv2/highgui/ios.h>

@interface ViewController () <CvVideoCameraDelegate>
@property (nonatomic, strong) CvVideoCamera *videoCamera;
@property NSMutableArray *states;
@property BOOL currentState;
@property NSInteger count;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
    
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
//    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    
    self.videoCamera.rotateVideo = YES;
    self.videoCamera.delegate = self;
    
    self.states = [NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil];
    self.currentState = FALSE;
    self.count = 0;
    
    if (!self.ip) {
        self.ip = @"192.168.10.104";
    }
    
    
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.videoCamera start];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(cv::Mat&)image;
{
    // グレースケール画像に変換
    cv::Mat copyMat;
    cv::Mat grayMat;
    
    image.copyTo( copyMat );
    cv::cvtColor(image, grayMat, CV_BGR2GRAY);
    
    cv::equalizeHist( grayMat, grayMat );
    
    // 分類器の読み込み
    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2"
                                                     ofType:@"xml"];
    std::string cascade_path = (char *)[path UTF8String];
    cv::CascadeClassifier cascade;
    
    if (!cascade.load(cascade_path)) {
        
        NSLog(@"Couldn't load haar cascade file.");
    }
    
    // 探索
    std::vector<cv::Rect> objects;
    cascade.detectMultiScale(grayMat, objects,      // 画像，出力矩形
                             1.10, 2,                // 縮小スケール，最低矩形数
                             0|CV_HAAR_SCALE_IMAGE,   // （フラグ）
                             cv::Size(70, 70));     // 最小矩形
    
    // 結果の描画
    std::vector<cv::Rect>::const_iterator r = objects.begin();
    for(; r != objects.end(); ++r) {
        NSLog(@"find face!¥n");
        cv::Point center;
        int radius;
        center.x = cv::saturate_cast<int>((r->x + r->width*0.5));
        center.y = cv::saturate_cast<int>((r->y + r->height*0.5));
        radius = cv::saturate_cast<int>((r->width + r->height)*0.25);
        cv::circle(image, center, radius, cv::Scalar(80,80,255), 3, 8, 0 );
        
    }
    
    // 蓄積の更新
    NSNumber *state;
    if (objects.size() >0) {
        state = [NSNumber numberWithInt:1];
    
    } else {
        state = [NSNumber numberWithInt:0];
    }
    
    self.states[self.count] = state;
    
    self.count += 1;
    if (self.count >= 10) {
        self.count = 0;
    }
    
    // 過去10回より顔判定
    int sum = 0;
    for (int i=0; i<10; i++) {
        if (self.states[i] == [NSNumber numberWithInt:1]) {
            sum +=1;
        }
    }
    
    int tempState;
    if (sum  >=7) {
        tempState = 1;
        
    } else {
        tempState = 0;
    }
    
    // ライトの点灯とグローバル状態の更新
    if (self.currentState ==0 && tempState == 1) {
        self.currentState = 1;
        
        NSString *dataString = @"{\"bri\":200, \"hue\":50000, \"on\":true}";
        NSData *postBodyData = [NSData dataWithBytes: [dataString UTF8String] length:[dataString length]];
        
        NSString *urlstr = [NSString stringWithFormat:@"%@%@%@",@"http://", self.ip, @"/api/2UtculltMK97O1Bw/lights/1/state"];
        
        NSString *urlstr2 = [NSString stringWithFormat:@"%@%@%@",@"http://", self.ip, @"/api/2UtculltMK97O1Bw/lights/2/state"];
        
        NSString *urlstr3 = [NSString stringWithFormat:@"%@%@%@",@"http://", self.ip, @"/api/2UtculltMK97O1Bw/lights/3/state"];
        
        NSURL *url = [NSURL URLWithString:urlstr];
        NSURL *url2 = [NSURL URLWithString:urlstr2];
        NSURL *url3 = [NSURL URLWithString:urlstr3];
        
        NSMutableURLRequest *myMutableRequest = [[NSMutableURLRequest alloc] initWithURL:url];
        NSMutableURLRequest *myMutableRequest2 = [[NSMutableURLRequest alloc] initWithURL:url2];
        NSMutableURLRequest *myMutableRequest3 = [[NSMutableURLRequest alloc] initWithURL:url3];
        
        [myMutableRequest setHTTPMethod:@"PUT"];
        [myMutableRequest2 setHTTPMethod:@"PUT"];
        [myMutableRequest3 setHTTPMethod:@"PUT"];
        
        [myMutableRequest setHTTPBody:postBodyData];
        [myMutableRequest2 setHTTPBody:postBodyData];
        [myMutableRequest3 setHTTPBody:postBodyData];
        
        [NSURLConnection connectionWithRequest:myMutableRequest delegate:nil];
        [NSURLConnection connectionWithRequest:myMutableRequest2 delegate:nil];
        [NSURLConnection connectionWithRequest:myMutableRequest3 delegate:nil];
        
        
        // APIアクセス
        if (self.api) {
            NSURL *apiurl = [NSURL URLWithString:self.api];
            NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:apiurl];
            [mutableRequest setHTTPMethod:@"GET"];
            [NSURLConnection connectionWithRequest:mutableRequest delegate:nil];
        }
        
        
    } else if (self.currentState ==1 && tempState == 0) {
        self.currentState = 0;
        
        NSString *dataString = @"{\"bri\":200, \"hue\":50000, \"on\":false}";
        NSData *postBodyData = [NSData dataWithBytes: [dataString UTF8String] length:[dataString length]];
        
        NSString *urlstr = [NSString stringWithFormat:@"%@%@%@",@"http://", self.ip, @"/api/2UtculltMK97O1Bw/lights/1/state"];
        
        NSString *urlstr2 = [NSString stringWithFormat:@"%@%@%@",@"http://", self.ip, @"/api/2UtculltMK97O1Bw/lights/2/state"];
        
        NSString *urlstr3 = [NSString stringWithFormat:@"%@%@%@",@"http://", self.ip, @"/api/2UtculltMK97O1Bw/lights/3/state"];
        
        
        NSURL *url = [NSURL URLWithString:urlstr];
        NSURL *url2 = [NSURL URLWithString:urlstr2];
        NSURL *url3 = [NSURL URLWithString:urlstr3];
        
        NSMutableURLRequest *myMutableRequest = [[NSMutableURLRequest alloc] initWithURL:url];
        NSMutableURLRequest *myMutableRequest2 = [[NSMutableURLRequest alloc] initWithURL:url2];
        NSMutableURLRequest *myMutableRequest3 = [[NSMutableURLRequest alloc] initWithURL:url3];
        
        [myMutableRequest setHTTPMethod:@"PUT"];
        [myMutableRequest2 setHTTPMethod:@"PUT"];
        [myMutableRequest3 setHTTPMethod:@"PUT"];
        
        [myMutableRequest setHTTPBody:postBodyData];
        [myMutableRequest2 setHTTPBody:postBodyData];
        [myMutableRequest3 setHTTPBody:postBodyData];
        
        [NSURLConnection connectionWithRequest:myMutableRequest delegate:nil];
        [NSURLConnection connectionWithRequest:myMutableRequest2 delegate:nil];
        [NSURLConnection connectionWithRequest:myMutableRequest3 delegate:nil];
    }
    
    self.imageView.image = MatToUIImage(image);

}

#endif
@end
