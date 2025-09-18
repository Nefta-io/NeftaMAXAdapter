//
//  InterstitialObjC.h
//  MaxIntegration
//
//  Created by Tomaz Treven on 23. 5. 25.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <NeftaSDK/NeftaSDK.h>

@interface InterstitialObjC : NSObject<MAAdDelegate, MAAdRevenueDelegate>

@property (nonatomic, strong) MAInterstitialAd * _Nullable dynamicInterstitial;
@property (nonatomic, assign) double dynamicAdRevenue;
@property (nonatomic, strong) AdInsight * _Nullable dynamicInsight;
@property (nonatomic, assign) int consecutiveDynamicFails;
@property (nonatomic, strong) MAInterstitialAd * _Nullable defaultInterstitial;
@property (nonatomic, assign) double defaultAdRevenue;

@property (weak, nonatomic) UIView *placeholder;
@property (weak, nonatomic) UISwitch *loadSwitch;
@property (weak, nonatomic) UIButton *showButton;
@property (weak, nonatomic) UILabel *status;

-(instancetype _Nonnull)initWith:(UIView * _Nonnull)placeholder loadSwitch:(UISwitch * _Nonnull)loadSwitch showButton:(UIButton * _Nonnull)showButton status:(UILabel * _Nonnull)status;
@end
