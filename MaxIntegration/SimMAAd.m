//
//  SimUtil.m
//  MaxIntegration
//
//  Created by Tomaz Treven on 10. 11. 25.
//

#import "SimMAAd.h"

@implementation SimMAAd
+ (SimMAAd *)create {
    SimMAAd *ad = [SimMAAd alloc];
    return ad;
}
- (NSString *)adUnitIdentifier {
    return _simAdUnitIdentifier;
}
-(MAAdFormat *)format {
    return _simFormat;
}
-(NSString *)networkName {
    return _simNetworkName;
}
-(double)revenue {
    return _simRevenue;
}
-(NSString *)revenuePrecision {
    return _simRevenuePrecision;
}
@end

@implementation SMAInterstitialAd
- (instancetype)initWithAdUnitIdentifier:(NSString *)adUnitId {
    return self;
}
@end

@implementation SMARewardedAd
- (instancetype)initWithAdUnitId:(NSString *)adUnitId {
    return self;
}
+ (instancetype)sharedWithAdUnitIdentifier:(NSString *)adUnitIdentifier {
    return [self alloc];
}
@end
