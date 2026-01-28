//
//  InterstitialObjC.m
//  MaxIntegration
//
//  Created by Tomaz Treven on 23. 5. 25.
//

#import "InterstitialObjC.h"
#import "ALNeftaMediationAdapter.h"

NSString * const AdUnitA = @"e5dc3548d4a0913f";
NSString * const AdUnitB = @"6d318f954e2630a8";
const int TimeoutInSeconds = 5;

@implementation TrackObjC

- (instancetype)initWithAdUnit:(NSString *)adUnit {
    self = [super init];
    if (self) {
        _adUnitId = [adUnit copy];
        
        _interstitial = [[MAInterstitialAd alloc] initWithAdUnitIdentifier: adUnit];
    
        _interstitial.delegate = self;
        _interstitial.revenueDelegate = self;
    }
    return self;
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error {
    [ALNeftaMediationAdapter OnExternalMediationRequestFailWithInterstitial: _interstitial error: error];
    
    [[InterstitialObjC sharedInstance] log: @"Load failed %@: %@", adUnitIdentifier, error];
    
    [self OnLoadFail];
}

- (void)OnLoadFail {
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
        [[InterstitialObjC sharedInstance] RetryLoadTracks];
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
    
    [[InterstitialObjC sharedInstance] RetryLoadTracks];
}

- (void)didHideAd:(MAAd *)ad {
    [[InterstitialObjC sharedInstance] log: @"didHideAd %@", ad];
    
    _state = Idle;
    
    [[InterstitialObjC sharedInstance] RetryLoadTracks];
}

@end

@implementation InterstitialObjC

static InterstitialObjC *instance = nil;

- (void)LoadTracks {
    [self LoadTrack: _trackA otherState: _trackB.state];
    [self LoadTrack: _trackB otherState: _trackA.state];
}

- (void)LoadTrack:(TrackObjC * _Nonnull)track otherState:(State)otherState {
    if (track.state == Idle) {
        if (otherState == LoadingWithInsights) {
            if (_isFirstResponseReceived) {
                [self LoadDefault: track];
            }
        } else {
            [self GetInsightsAndLoad: track];
        }
    }
}

- (void)GetInsightsAndLoad:(TrackObjC * _Nonnull)track {
    track.state = LoadingWithInsights;
    
    [NeftaPlugin._instance GetInsights: Insights.Interstitial previousInsight: track.insight callback: ^(Insights * insights) {
        [self log: @"Load with insight: %@", insights];
        if (insights._interstitial != nil) {
            track.insight = insights._interstitial;
            NSString *bidFloorParam = [NSString stringWithFormat:@"%.10f", track.insight._floorPrice];

            [track.interstitial setExtraParameterForKey: @"disable_auto_retries" value: @"true"];
            [track.interstitial setExtraParameterForKey: @"jC7Fp" value: bidFloorParam];
            
            [ALNeftaMediationAdapter OnExternalMediationRequestWithInterstitial: track.interstitial insight: track.insight];
            
            [self log: @"Loading Interstitial with insight: %@ floor: %@", track.insight, bidFloorParam];
            [track.interstitial loadAd];
        } else {
            [track OnLoadFail];
        }
    } timeout: TimeoutInSeconds];
}

- (void)LoadDefault:(TrackObjC * _Nonnull)track {
    track.state = Loading;
    
    [self log: @"Loading %@ as Default", track.adUnitId];
    
    [track.interstitial setExtraParameterForKey: @"disable_auto_retries" value: @"false"];
    [track.interstitial setExtraParameterForKey: @"jC7Fp" value: @""];
    
    [ALNeftaMediationAdapter OnExternalMediationRequestWithInterstitial: track.interstitial];
    
    [track.interstitial loadAd];
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
        
        _trackA = [[TrackObjC alloc] initWithAdUnit: AdUnitA];
        _trackB = [[TrackObjC alloc] initWithAdUnit: AdUnitB];
        
        [_loadSwitch addTarget:self action:@selector(OnLoadSwitch:) forControlEvents:UIControlEventValueChanged];
        [_showButton addTarget:self action:@selector(OnShowClick:) forControlEvents:UIControlEventTouchUpInside];
        
        _showButton.enabled = false;
    }
    return self;
}

- (void)OnLoadSwitch:(UISwitch *)sender {
    if (sender.isOn) {
        [self LoadTracks];
    }
}

- (void)OnShowClick:(UIButton *)sender {
    bool isShown = false;
    if (_trackA.state == Ready) {
        if (_trackB.state == Ready && _trackB.revenue > _trackA.revenue) {
            isShown = [self TryShow: _trackB];
        }
        if (!isShown) {
            isShown = [self TryShow: _trackA];
        }
    }
    if (!isShown && _trackB.state == Ready) {
        isShown = [self TryShow: _trackB];
    }
    
    [self UpdateShowButton];
}

- (bool)TryShow:(TrackObjC *)track {
    track.revenue = -1;
    if (track.interstitial.ready) {
        track.state = Shown;
        [track.interstitial showAd];
        return true;
    }
    track.state = Idle;
    [self RetryLoadTracks];
    return false;
}

- (void) RetryLoadTracks {
    if (_loadSwitch.isOn) {
        [self LoadTracks];
    }
}

- (void) OnTrackLoad:(bool)success {
    if (success) {
        [self UpdateShowButton];
    }
    
    _isFirstResponseReceived = true;
    [self RetryLoadTracks];
}

- (void)UpdateShowButton {
    [_showButton setEnabled: _trackA.state == Ready || _trackB.state == Ready];
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
