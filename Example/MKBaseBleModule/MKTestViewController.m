//
//  MKTestViewController.m
//  MKBaseBleModule_Example
//
//  Created by aa on 2022/9/2.
//  Copyright © 2022 aadyx2007@163.com. All rights reserved.
//

#import "MKTestViewController.h"

#import "MKBLEBaseSDKAdopter.h"

@interface MKTestViewController ()

@end

@implementation MKTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *string1 = [MKBLEBaseSDKAdopter binaryByhex:@"0"];
    NSString *string2 = [MKBLEBaseSDKAdopter binaryByhex:@"110"];
    NSString *string3 = [MKBLEBaseSDKAdopter binaryByhex:@"aa"];
    
    NSString *binary = [MKBLEBaseSDKAdopter getHexByBinary:@"10101010"];
    
    NSString *binary11 = [MKBLEBaseSDKAdopter getHexByBinary:@"100000000001100000000001"];
    
    BOOL result1 = [MKBLEBaseSDKAdopter checkHexCharacter:@"abcdef0"];
    
    BOOL result2 = [MKBLEBaseSDKAdopter checkHexCharacter:@"0a"];
    
    BOOL result3 = [MKBLEBaseSDKAdopter checkHexCharacter:@"asd"];
    
    BOOL result4 = [MKBLEBaseSDKAdopter checkHexCharacter:@"1"];
    
    
    NSLog(@"%@",binary11);
}

@end
