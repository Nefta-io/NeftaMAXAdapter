//
//  ALNeftaRewarded.m
//  MaxIntegration
//
//  Created by Tomaz Treven on 3. 10. 24.
//

#import "ALNeftaRewarded.h"

static NSString* _lastCreativeId;
static NSString* _lastAuctionId;

@implementation ALNeftaRewarded
- (instancetype)initWithId:(NSString *)id listener:(id<MARewardedAdapterDelegate>)listener {
    self = [super init];
    if (self) {
        _rewarded = [[NRewarded alloc] initWithId: id];
        _rewarded._listener = self;
        _listener = listener;
    }
    return self;
}

- (void) SetCustomParameterWithProvider:(NSString *)provider value: (NSString *)value {
    [_rewarded SetCustomParameterWithProvider: provider value: value];
}
- (void) Load {
    [_rewarded Load];
}
- (int) CanShow {
    return (int)[_rewarded CanShow];
}
- (void) Show:(UIViewController *)viewController {
    [_rewarded Show: viewController];
}

- (void) OnLoadFailWithAd:(NAd * _Nonnull)ad error:(NError * _Nonnull)error {
    MAAdapterError* mError = [ALNeftaAd NLoadToAdapterError: error];
    [_listener didFailToLoadRewardedAdWithError: mError];
}
- (void) OnLoadWithAd:(NAd * _Nonnull)ad width:(NSInteger)width height:(NSInteger)height {
    [_listener didLoadRewardedAd];
}
- (void) OnShowFailWithAd:(NAd * _Nonnull)ad error:(NError * _Nonnull)error {
    [_listener didFailToLoadRewardedAdWithError: MAAdapterError.adDisplayFailedError];
}
- (void) OnShowWithAd:(NAd * _Nonnull)ad {
    _lastAuctionId = ad._bid._auctionId;
    _lastCreativeId = ad._bid._creativeId;
    [_listener didDisplayRewardedAd];
}
- (void) OnClickWithAd:(NAd * _Nonnull)ad {
    [_listener didClickRewardedAd];
}
- (void) OnRewardWithAd:(NAd * _Nonnull)ad {
    _giveReward = true;
    if (_reward == nil) {
        _reward = [MAReward rewardWithAmount: MAReward.defaultAmount label: MAReward.defaultLabel];
    }
}
- (void) OnCloseWithAd:(NAd * _Nonnull)ad {
    if (_giveReward) {
        [_listener didRewardUserWithReward: _reward];
    }
    [_listener didHideRewardedAd];
}

+ (NSString*) GetLastAuctionId {
    return _lastAuctionId;
}
+ (NSString*) GetLastCreativeId {
    return _lastCreativeId;
}
@end
