//
//  SimUtil.h
//  MaxIntegration
//
//  Created by Tomaz Treven on 10. 11. 25.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>

@interface SimMAAd : MAAd
+ (SimMAAd *)create;
@property (nonatomic, copy, readwrite) NSString *simAdUnitIdentifier;
@property (nonatomic, strong, readwrite) MAAdFormat *simFormat;
@property (nonatomic, copy, readwrite) NSString *simNetworkName;
@property (nonatomic, assign, readwrite) double simRevenue;
@property (nonatomic, copy, readwrite) NSString *simRevenuePrecision;
@end

@interface SMAInterstitialAd : MAInterstitialAd
- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitId;
@end

@interface SMARewardedAd : MARewardedAd
- (instancetype)initWithAdUnitId:(NSString *)adUnitId;
+ (instancetype)sharedWithAdUnitIdentifier:(NSString *)adUnitIdentifier;
@end
