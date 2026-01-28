//
//  InterstitialObjC.h
//  MaxIntegration
//
//  Created by Tomaz Treven on 23. 5. 25.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <NeftaSDK/NeftaSDK.h>

typedef enum {
    Idle,
    LoadingWithInsights,
    Loading,
    Ready,
    Shown
} State;


@interface TrackObjC : NSObject<MAAdDelegate, MAAdRevenueDelegate>

@property (nonatomic, strong) NSString * _Nonnull adUnitId;
@property (nonatomic, strong) MAInterstitialAd * _Nonnull interstitial;
@property (nonatomic, assign) State state;
@property (nonatomic, strong) AdInsight * _Nullable insight;
@property (nonatomic, assign) double revenue;
@property (nonatomic, assign) int consecutiveAdFails;

- (instancetype _Nonnull )initWithAdUnit:(NSString * _Nonnull)adUnit;

-(void)OnLoadFail;
-(void)retryLoad;

@end

@interface InterstitialObjC : NSObject

@property (nonatomic, copy, readonly) TrackObjC * _Nonnull trackA;
@property (nonatomic, copy, readonly) TrackObjC * _Nonnull trackB;
@property (nonatomic, assign) bool isFirstResponseReceived;


@property (weak, nonatomic) UISwitch *loadSwitch;
@property (weak, nonatomic) UIButton *showButton;
@property (weak, nonatomic) UILabel *status;

+(InterstitialObjC * _Nonnull)sharedInstance;

-(instancetype _Nonnull)initWithLoad:(UISwitch * _Nonnull)load show:(UIButton * _Nonnull)show status:(UILabel * _Nonnull)status;
-(void)LoadTrack:(TrackObjC * _Nonnull)track otherState:(State)otherState;
-(void)OnTrackLoad:(bool)success;
-(void)RetryLoadTracks;
-(void)log:(NSString * _Nonnull)format, ...;
@end
