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

@implementation AdRequestObjc

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error {
    [ALNeftaMediationAdapter OnExternalMediationRequestFailWithInterstitial: _interstitial error: error];
    
    [[InterstitialObjC sharedInstance] log: @"Load failed %@: %@", adUnitIdentifier, error];
    
    _interstitial = nil;
    _consecutiveAdFails++;
    [self retryLoad];
    
    [[InterstitialObjC sharedInstance] OnTrackLoad: false];
}

- (void)didLoadAd:(MAAd *)ad {
    [ALNeftaMediationAdapter OnExternalMediationRequestLoadWithInterstitial: _interstitial ad: ad];
    
    [[InterstitialObjC sharedInstance] log: @"Loaded %@: %f", ad, ad.revenue];
    
    _insight = nil;
    _consecutiveAdFails = 0;
    _revenue = ad.revenue;
    _state = Ready;
    
    [[InterstitialObjC sharedInstance] OnTrackLoad: false];
}

- (void)retryLoad {
    // As per MAX recommendations, retry with exponentially higher delays up to 64s
    // In case you would like to customize fill rate / revenue please contact our customer support
    int delayInSeconds = (int[]){ 0, 2, 4, 8, 16, 32, 64 }[MIN(_consecutiveAdFails, 6)];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        self.state = Idle;
        [[InterstitialObjC sharedInstance] RetryLoading];
    });
}

- (void)didPayRevenueForAd:(nonnull MAAd *)ad {
    [ALNeftaMediationAdapter OnExternalMediationImpression: ad];
    
    [[InterstitialObjC sharedInstance] log: @"didPayRevenueForAd %@ revenue: %f network: %@", ad.adUnitIdentifier, ad.revenue, ad.networkName];
}

- (void)didClickAd:(MAAd *)ad {
    [ALNeftaMediationAdapter OnExternalMediationClick: ad];
    
    [[InterstitialObjC sharedInstance] log: @"didClickAd %@", ad];
}

- (void)didDisplayAd:(MAAd *)ad {
    [[InterstitialObjC sharedInstance] log: @"didDisplayAd %@", ad];
}

- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error {
    [[InterstitialObjC sharedInstance] log: @"didFailToDisplayAd %@: %@", ad, error];
}

- (void)didHideAd:(MAAd *)ad {
    [[InterstitialObjC sharedInstance] log: @"didHideAd %@", ad];
    
    [[InterstitialObjC sharedInstance] RetryLoading];
}

@end

@implementation InterstitialObjC

static InterstitialObjC *instance = nil;

- (void)StartLoading {
    [self Load: _adRequestA otherState: _adRequestB.state];
    [self Load: _adRequestB otherState: _adRequestA.state];
}

- (void)Load:(AdRequestObjc * _Nonnull)request otherState:(State)otherState {
    if (request.state == Idle) {
        if (otherState != LoadingWithInsights) {
            [self GetInsightsAndLoad: request];
        } else if (_isFirstResponseReceived) {
            [self LoadDefault: request];
        }
    }
}

- (void)GetInsightsAndLoad:(AdRequestObjc * _Nonnull)adRequest {
    [NeftaPlugin._instance GetInsights: Insights.Interstitial previousInsight: adRequest.insight callback: ^(Insights * insights) {
        [self log: @"Load with insight: %@", insights];
        if (insights._interstitial != nil) {
            adRequest.insight = insights._interstitial;
            NSString *bidFloorParam = [NSString stringWithFormat:@"%.10f", adRequest.insight._floorPrice];
            adRequest.interstitial = [[MAInterstitialAd alloc] initWithAdUnitIdentifier: DynamicAdUnitId];
            adRequest.interstitial.delegate = adRequest;
            [adRequest.interstitial setExtraParameterForKey: @"disable_auto_retries" value: @"true"];
            [adRequest.interstitial setExtraParameterForKey: @"jC7Fp" value: bidFloorParam];
            
            [ALNeftaMediationAdapter OnExternalMediationRequestWithInterstitial: adRequest.interstitial insight: adRequest.insight];
            
            [self log: @"Loading Interstitial with insight: %@ floor: %@", adRequest.insight, bidFloorParam];
            [adRequest.interstitial loadAd];
        } else {
            adRequest.consecutiveAdFails++;
            [adRequest retryLoad];
        }
    } timeout: TimeoutInSeconds];
}

- (void)LoadDefault:(AdRequestObjc * _Nonnull)adRequest {
    adRequest.state = Loading;
    
    [self log: @"Loading %@ as Default", adRequest.adUnitId];
    
    adRequest.interstitial = [[MAInterstitialAd alloc] initWithAdUnitIdentifier: adRequest.adUnitId];
    adRequest.interstitial.delegate = adRequest;
    
    [ALNeftaMediationAdapter OnExternalMediationRequestWithInterstitial: adRequest.interstitial];
    
    [adRequest.interstitial loadAd];
}

+ (InterstitialObjC *)sharedInstance {
    return instance;
}

- (instancetype)initWithLoad:(UISwitch *)load show:(UIButton *)show status:(UILabel *)status {
    self = [super init];
    if (self) {
        instance = self;
        
        _loadSwitch = load;
        _showButton = show;
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
    if (_adRequestA.state == Ready) {
        if (_adRequestB.state == Ready && _adRequestB.revenue > _adRequestA.revenue) {
            isShown = [self TryShow: _adRequestB];
        }
        if (!isShown) {
            isShown = [self TryShow: _adRequestA];
        }
    }
    if (!isShown && _adRequestB.state == Ready) {
        isShown = [self TryShow: _adRequestB];
    }
    
    [self UpdateShowButton];
}

- (bool)TryShow:(AdRequestObjc *)adRequest {
    adRequest.state = Idle;
    adRequest.revenue = -1;
    
    if (adRequest.interstitial.ready) {
        [adRequest.interstitial showAd];
        return true;
    }
    [self RetryLoading];
    return false;
}

- (void) RetryLoading {
    if (_loadSwitch.isOn) {
        [self StartLoading];
    }
}

- (void) OnTrackLoad:(bool)success {
    if (success) {
        [self UpdateShowButton];
    }
    
    _isFirstResponseReceived = true;
    [self RetryLoading];
}

- (void)UpdateShowButton {
    [_showButton setEnabled: _adRequestA.state == Ready || _adRequestB.state == Ready];
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
