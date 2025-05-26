//
//  InterstitialObjC.m
//  MaxIntegration
//
//  Created by Tomaz Treven on 23. 5. 25.
//

#import "InterstitialObjC.h"
#import "ALNeftaMediationAdapter.h"

NSString * const DefaultAdUnitId = @"6d318f954e2630a8";

NSString * const AdUnitIdInsightName = @"recommended_interstitial_ad_unit_id";
NSString * const FloorPriceInsightName = @"calculated_user_floor_price_interstitial";

@implementation InterstitialObjC

- (void)GetInsightsAndLoad {
    _isLoadRequested = true;
    
    [NeftaPlugin._instance GetBehaviourInsight: @[AdUnitIdInsightName, FloorPriceInsightName] callback: ^(NSDictionary<NSString *, Insight *> *insights) {
        [self OnBehaviourInsight: insights];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (self.isLoadRequested) {
            self.recommendedAdUnitId = nil;
            self.calculatedBidFloor = 0;
            [self Load];
        }
    });
}

-(void)OnBehaviourInsight:(NSDictionary<NSString *, Insight *> *)insights {
    _recommendedAdUnitId = nil;
    _calculatedBidFloor = 0;
    
    Insight* recommendAdUnitInsight = insights[AdUnitIdInsightName];
    if (recommendAdUnitInsight != nil) {
        _recommendedAdUnitId = recommendAdUnitInsight._string;
    }
    Insight* floorPriceInsight = insights[FloorPriceInsightName];
    if (floorPriceInsight != nil) {
        _calculatedBidFloor = floorPriceInsight._float;
    }
    
    NSLog(@"OnBehaviourInsight for Interstitial recommended AdUnit: %@ calculated bid floor: %f", _recommendedAdUnitId, _calculatedBidFloor);
    
    if (_isLoadRequested) {
        [self Load];
    }
}

- (void)Load {
    _isLoadRequested = false;
    
    NSString* adUnitId = DefaultAdUnitId;
    if (_recommendedAdUnitId != nil && _recommendedAdUnitId.length > 0) {
        adUnitId = _recommendedAdUnitId;
    }
    
    _interstitial = [[MAInterstitialAd alloc] initWithAdUnitIdentifier: adUnitId];
    _interstitial.delegate = self;
    [_interstitial loadAd];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error {
    [ALNeftaMediationAdapter OnExternalMediationRequestFail: AdTypeInterstitial recommendedAdUnitId: _recommendedAdUnitId calculatedFloorPrice: _calculatedBidFloor adUnitIdentifier: adUnitIdentifier error: error];
    
    [self SetInfo: @"didFailToLoadAdForAdUnitIdentifier %@: %@", adUnitIdentifier, error];
    
    _consecutiveAdFails++;
    // As per MAX recommendations, retry with exponentially higher delays up to 64s
         // In case you would like to customize fill rate / revenue please contact our customer support
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int[]){ 0, 2, 4, 8, 32, 64 }[MIN(_consecutiveAdFails, 5)] * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self GetInsightsAndLoad];
    });
}

- (void)didLoadAd:(MAAd *)ad {
    [ALNeftaMediationAdapter OnExternalMediationRequestLoad: AdTypeInterstitial recommendedAdUnitId: _recommendedAdUnitId calculatedFloorPrice: _calculatedBidFloor ad: ad];
    
    [self SetInfo: @"didFailToLoadAdForAdUnitIdentifier %@: %f", ad, ad.revenue];
    
    _consecutiveAdFails = 0;
    _showButton.enabled = true;
}

-(instancetype)initWith:(UIButton *)loadButton showButton:(UIButton *)showButton status:(UILabel *)status {
    self = [super init];
    if (self) {
        _loadButton = loadButton;
        _showButton = showButton;
        _status = status;
        
        [_loadButton addTarget:self action:@selector(OnLoadClick:) forControlEvents:UIControlEventTouchUpInside];
        [_showButton addTarget:self action:@selector(OnShowClick:) forControlEvents:UIControlEventTouchUpInside];
        
        _showButton.enabled = false;
    }
    return self;
}

- (void)OnLoadClick:(UIButton *)sender {
    [self GetInsightsAndLoad];
}

- (void)OnShowClick:(UIButton *)sender {
    [_interstitial showAd];
    
    _showButton.enabled = false;
}

- (void)didDisplayAd:(MAAd *)ad {
    [self SetInfo: @"didDisplayAd %@", ad];
}

- (void)didClickAd:(MAAd *)ad {
    [self SetInfo: @"didClickAd %@", ad];
}

- (void)didHideAd:(MAAd *)ad {
    [self SetInfo: @"didHideAd %@", ad];
}

- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error {
    [self SetInfo: @"didFailToDisplayAd %@: %@", ad, error];
}

- (void)didPayRevenueForAd:(nonnull MAAd *)ad {
    [ALNeftaMediationAdapter OnExternalMediationImpression: ad];
    
    [self SetInfo: @"didPayRevenueForAd %@ revenue: %f network: %@", ad.adUnitIdentifier, ad.revenue, ad.networkName];
}

-(void)SetInfo:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    
    NSString *info = [[NSString alloc] initWithFormat:format arguments:args];
    
    NSLog(@"Integration InterstitialObjC: %@", info);
    _status.text = info;
}

@end
