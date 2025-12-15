//
//  SimUtil.h
//  MaxIntegration
//
//  Created by Tomaz Treven on 10. 11. 25.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>

@interface SMAInterstitialAd : MAInterstitialAd
- (instancetype _Nonnull )initWithAdUnitIdentifier:(NSString * _Nonnull)adUnitId;
@end

@interface SMARewardedAd : MARewardedAd
- (instancetype _Nonnull)initWithAdUnitId:(NSString * _Nonnull)adUnitId;
+ (instancetype _Nonnull)sharedWithAdUnitIdentifier:(NSString * _Nonnull)adUnitIdentifier;
@end

@interface SMAMediatedNetworkInfo : MAMediatedNetworkInfo
@property (nonatomic, copy) NSString * _Nonnull simName;
+ (SMAMediatedNetworkInfo * _Nonnull)create:(NSString * _Nonnull)name;
@end

@interface SMANetworkResponseInfo : MANetworkResponseInfo
@property (nonatomic, strong) SMAMediatedNetworkInfo * _Nonnull simMediatedNetwork;
@property (nonatomic, assign) MAAdLoadState simAdLoadState;
@property (nonatomic, assign) BOOL simBidding;
@property (nonatomic, assign) NSTimeInterval simLatency;
@property (nonatomic, strong) MAError * _Nullable simError;
@end

@interface SMAAdWaterfallInfo : MAAdWaterfallInfo
@property (nonatomic, copy) NSString * _Nonnull simName;
@property (nonatomic, copy) NSString * _Nonnull simTestName;
@property (nonatomic, copy) NSArray<SMANetworkResponseInfo *> * _Nonnull simNetworkResponses;
+ (SMAAdWaterfallInfo * _Nonnull)create:(NSString *_Nonnull)name testName:(NSString *_Nonnull)testName responses:(NSArray<NSNumber *> * _Nonnull) responses;
@end

@interface SMAError : MAError
@property (nonatomic, assign) int status;
@property (nonatomic, copy) NSString * _Nonnull simMessage;
@property (nonatomic, strong) SMAAdWaterfallInfo * _Nonnull simWaterfall;
@property (nonatomic, assign) double simRequestLatency;
+ (SMAError * _Nonnull)create:(NSInteger)status message:(NSString * _Nonnull)message;
@end

@interface SimMAAd : MAAd
+ (SimMAAd * _Nonnull)create;
@property (nonatomic, copy) NSString * _Nonnull simAdUnitIdentifier;
@property (nonatomic, strong) MAAdFormat * _Nonnull simFormat;
@property (nonatomic, copy) NSString * _Nonnull simNetworkName;
@property (nonatomic, assign) double simRevenue;
@property (nonatomic, copy) NSString * _Nonnull simRevenuePrecision;
@property (nonatomic, strong) MAAdWaterfallInfo * _Nonnull simWaterfall;
+ (SMAAdWaterfallInfo * _Nonnull)GetWaterfall:(NSString * _Nonnull)name testName:(NSString * _Nonnull)testName responses:(NSArray<NSNumber *> * _Nonnull) responses;
@end
