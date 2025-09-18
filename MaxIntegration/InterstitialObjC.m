//
//  InterstitialObjC.m
//  MaxIntegration
//
//  Created by Tomaz Treven on 23. 5. 25.
//

#import "InterstitialObjC.h"
#import "ALNeftaMediationAdapter.h"

NSString * const DynamicAdUnitId = @"e5dc3548d4a0913f";
NSString * const DefaultAdUnitId = @"6d318f954e2630a8";
const int TimeoutInSeconds = 5;

@implementation InterstitialObjC

- (void) StartLoading {
    if (_dynamicInterstitial == nil) {
        [self GetInsightsAndLoad: nil];
    }
    if (_defaultInterstitial == nil) {
        [self LoadDefault];
    }
}

- (void)GetInsightsAndLoad:(AdInsight * _Nullable)previousInsight {
    [NeftaPlugin._instance GetInsights: Insights.Interstitial previousInsight: previousInsight callback: ^(Insights * insights) {
        [self LoadWithInsights: insights];
    } timeout: TimeoutInSeconds];
}

-(void)LoadWithInsights:(Insights *) insights {
    _dynamicInsight = insights._interstitial;
    if (_dynamicInsight != nil) {
        NSString *bidFloorParam = [NSString stringWithFormat:@"%.10f", _dynamicInsight._floorPrice];
    
        [self log: @"Loading Interstitial with insight: %@ floor: %@", _dynamicInsight, bidFloorParam];
        _dynamicInterstitial = [[MAInterstitialAd alloc] initWithAdUnitIdentifier: DynamicAdUnitId];
        _dynamicInterstitial.delegate = self;
        [_dynamicInterstitial setExtraParameterForKey: @"disable_auto_retries" value: @"true"];
        [_dynamicInterstitial setExtraParameterForKey: @"jC7Fp" value: bidFloorParam];
        [_dynamicInterstitial loadAd];
        
        [ALNeftaMediationAdapter OnExternalMediationRequestWithInterstitial: _dynamicInterstitial insight: _dynamicInsight];
    }
}

- (void) LoadDefault {
    [self log: @"Loading Default Interstitial"];
    _defaultInterstitial = [[MAInterstitialAd alloc] initWithAdUnitIdentifier: DefaultAdUnitId];
    _defaultInterstitial.delegate = self;
    [_defaultInterstitial loadAd];
    
    [ALNeftaMediationAdapter OnExternalMediationRequestWithInterstitial: _defaultInterstitial];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error {
    if (adUnitIdentifier == DynamicAdUnitId) {
        [ALNeftaMediationAdapter OnExternalMediationRequestFailWithInterstitial: _dynamicInterstitial error: error];
        
        [self log: @"Load failed Dynamic %@: %@", adUnitIdentifier, error];
        
        _consecutiveDynamicFails++;
        // As per MAX recommendations, retry with exponentially higher delays up to 64s
        // In case you would like to customize fill rate / revenue please contact our customer support
        int delayInSeconds = (int[]){ 0, 2, 4, 8, 16, 32, 64 }[MIN(_consecutiveDynamicFails, 6)];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (self.loadSwitch.isOn) {
                [self GetInsightsAndLoad: self.dynamicInsight];
            }
        });
    } else {
        [ALNeftaMediationAdapter OnExternalMediationRequestFailWithInterstitial: _defaultInterstitial error: error];
        
        [self log: @"Load failed Default %@: %@", adUnitIdentifier, error];
        
        _defaultInterstitial = nil;
        if (_loadSwitch.isOn) {
            [self LoadDefault];
        }
    }

}

- (void)didLoadAd:(MAAd *)ad {
    if (ad.adUnitIdentifier == DynamicAdUnitId) {
        [ALNeftaMediationAdapter OnExternalMediationRequestLoadWithInterstitial: _dynamicInterstitial ad: ad];
        
        [self log: @"Load Dynamic %@: %f", ad, ad.revenue];
        
        _consecutiveDynamicFails = 0;
        _dynamicAdRevenue = ad.revenue;
    } else {
        [ALNeftaMediationAdapter OnExternalMediationRequestLoadWithInterstitial: _defaultInterstitial ad: ad];
        
        [self log: @"Load Default %@: %f", ad, ad.revenue];
        
        _defaultAdRevenue = ad.revenue;
    }

    [self UpdateShowButton];
}

- (void)didPayRevenueForAd:(nonnull MAAd *)ad {
    [ALNeftaMediationAdapter OnExternalMediationImpression: ad];
    
    [self log: @"didPayRevenueForAd %@ revenue: %f network: %@", ad.adUnitIdentifier, ad.revenue, ad.networkName];
}

- (void)didClickAd:(MAAd *)ad {
    [ALNeftaMediationAdapter OnExternalMediationClick: ad];
    
    [self log: @"didClickAd %@", ad];
}

-(instancetype)initWith:(UIView *)placeholder loadSwitch:(UISwitch *)loadSwitch showButton:(UIButton *)showButton status:(UILabel *)status {
    self = [super init];
    if (self) {
        _placeholder = placeholder;
        _loadSwitch = loadSwitch;
        _showButton = showButton;
        _status = status;
        
        [_loadSwitch addTarget:self action:@selector(OnLoadSwitch:) forControlEvents:UIControlEventValueChanged];
        [_showButton addTarget:self action:@selector(OnShowClick:) forControlEvents:UIControlEventTouchUpInside];
        
        _showButton.enabled = false;
    }
    return self;
}

- (void)OnLoadSwitch:(UISwitch *)sender {
    if (sender.isOn) {
        [self StartLoading];
    }
}

- (void)OnShowClick:(UIButton *)sender {
    bool isShown = false;
    if (_dynamicAdRevenue >= 0) {
        if (_defaultAdRevenue > _dynamicAdRevenue) {
            isShown = [self TryShowDefault];
        }
        if (!isShown) {
            isShown = [self TryShowDynamic];
        }
    }
    if (!isShown && _defaultAdRevenue >= 0) {
        [self TryShowDefault];
    }
    
    [self UpdateShowButton];
}

- (bool)TryShowDynamic {
    bool isShown = false;
    if (_dynamicInterstitial.ready) {
        [_dynamicInterstitial showAd];
        isShown = true;
    }
    _dynamicAdRevenue = -1;
    _dynamicInterstitial = nil;
    return isShown;
}

- (bool)TryShowDefault {
    bool isShown = false;
    if (_defaultInterstitial.ready) {
        [_defaultInterstitial showAd];
        isShown = true;
    }
    _defaultAdRevenue = -1;
    _defaultInterstitial = nil;
    return isShown;
}

- (void)didDisplayAd:(MAAd *)ad {
    [self log: @"didDisplayAd %@", ad];
}

- (void)didHideAd:(MAAd *)ad {
    [self log: @"didHideAd %@", ad];
    
    // start new cycle
    if (_loadSwitch.isOn) {
        [self StartLoading];
    }
}

- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error {
    [self log: @"didFailToDisplayAd %@: %@", ad, error];
}

- (void)UpdateShowButton {
    [_showButton setEnabled: _dynamicAdRevenue >= 0 || _defaultAdRevenue >= 0];
}

- (void)log:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    
    NSString *formattedLog = [[NSString alloc] initWithFormat:format arguments:args];
    [_status setText: formattedLog];
    
    NSLog(@"NeftaPluginMAX Interstitial: %@", formattedLog);
    va_end(args);
}

@end
