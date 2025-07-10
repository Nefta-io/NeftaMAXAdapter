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

@property (nonatomic, strong) MAInterstitialAd *interstitial;
@property (nonatomic, strong) AdInsight *usedInsight;
@property (nonatomic, assign) int consecutiveAdFails;

@property (weak, nonatomic) UIView *placeholder;
@property (weak, nonatomic) UIButton *loadButton;
@property (weak, nonatomic) UIButton *showButton;

-(void)GetInsightsAndLoad;
-(void)Load:(Insights *)insights;
-(instancetype)initWith:(UIView *)placeholder loadButton:(UIButton *)loadButton showButton:(UIButton *)showButton;
@end
