//
//  InterstitialObjC.m
//  MaxIntegration
//
//  Created by Tomaz Treven on 23. 5. 25.
//

#import "InterstitialObjC.h"
#import "ALNeftaMediationAdapter.h"

NSString * const DefaultAdUnitId = @"6d318f954e2630a8";
const int TimeoutInSeconds = 5;

@implementation InterstitialObjC

- (void)GetInsightsAndLoad {
    [NeftaPlugin._instance GetInsights: Insights.Interstitial callback: ^(Insights * insights) {
        [self Load: insights];
    } timeout: TimeoutInSeconds];
}

-(void)Load:(Insights *) insights {
    NSString *selectedAdUnitId = DefaultAdUnitId;
    _usedInsight = insights._interstitial;
    if (_usedInsight != nil && _usedInsight._adUnit != nil) {
        selectedAdUnitId = _usedInsight._adUnit;
    }

    NSLog(@"Loading %@ insights %@", selectedAdUnitId, _usedInsight);
    _interstitial = [[MAInterstitialAd alloc] initWithAdUnitIdentifier: selectedAdUnitId];
    _interstitial.delegate = self;
    [_interstitial setExtraParameterForKey: @"disable_auto_retries" value: @"true"];
    [_interstitial loadAd];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error {
    [ALNeftaMediationAdapter OnExternalMediationRequestFail: AdTypeInterstitial adUnitIdentifier: adUnitIdentifier usedInsight: _usedInsight error: error];
    
    NSLog(@"didFailToLoadAdForAdUnitIdentifier %@: %@", adUnitIdentifier, error);
    
    _consecutiveAdFails++;
    // As per MAX recommendations, retry with exponentially higher delays up to 64s
    // In case you would like to customize fill rate / revenue please contact our customer support
    int delayInSeconds = (int[]){ 0, 2, 4, 8, 16, 32, 64 }[MIN(_consecutiveAdFails, 6)];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self GetInsightsAndLoad];
    });
}

- (void)didLoadAd:(MAAd *)ad {
    [ALNeftaMediationAdapter OnExternalMediationRequestLoad: AdTypeInterstitial ad: ad usedInsight: _usedInsight];
    
    NSLog(@"didLoadAd %@: %f", ad, ad.revenue);
    
    _consecutiveAdFails = 0;
    _showButton.enabled = true;
}

- (void)didPayRevenueForAd:(nonnull MAAd *)ad {
    [ALNeftaMediationAdapter OnExternalMediationImpression: ad];
    
    NSLog(@"didPayRevenueForAd %@ revenue: %f network: %@", ad.adUnitIdentifier, ad.revenue, ad.networkName);
}

-(instancetype)initWith:(UIView *)placeholder loadButton:(UIButton *)loadButton showButton:(UIButton *)showButton {
    self = [super init];
    if (self) {
        _placeholder = placeholder;
        _loadButton = loadButton;
        _showButton = showButton;
        
        [_loadButton addTarget:self action:@selector(OnLoadClick:) forControlEvents:UIControlEventTouchUpInside];
        [_showButton addTarget:self action:@selector(OnShowClick:) forControlEvents:UIControlEventTouchUpInside];
        
        _showButton.enabled = false;
    }
    return self;
}

- (void)OnLoadClick:(UIButton *)sender {
    NSLog(@"GetInsightsAndLoad...");
    [self GetInsightsAndLoad];
    _loadButton.enabled = false;
}

- (void)OnShowClick:(UIButton *)sender {
    [_interstitial showAd];
    
    _showButton.enabled = false;
}

- (void)didDisplayAd:(MAAd *)ad {
    NSLog(@"didDisplayAd %@", ad);
}

- (void)didClickAd:(MAAd *)ad {
    NSLog(@"didClickAd %@", ad);
}

- (void)didHideAd:(MAAd *)ad {
    NSLog(@"didHideAd %@", ad);
    _loadButton.enabled = true;
}

- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error {
    NSLog(@"didFailToDisplayAd %@: %@", ad, error);
}

@end
