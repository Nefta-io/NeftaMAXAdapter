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
@property (nonatomic, assign) NSString *recommendedAdUnitId;
@property (nonatomic, assign) double calculatedBidFloor;
@property (nonatomic, assign) BOOL isLoadRequested;

@property (weak, nonatomic) UIButton *loadButton;
@property (weak, nonatomic) UIButton *showButton;
@property (weak, nonatomic) UILabel *status;

-(void)GetInsightsAndLoad;
-(void)OnBehaviourInsight:(NSDictionary<NSString *, Insight *> *)insights;
-(void)Load;
-(instancetype)initWith:(UIButton *)loadButton showButton:(UIButton *)showButton status:(UILabel *)status;
-(void)SetInfo:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
@end
