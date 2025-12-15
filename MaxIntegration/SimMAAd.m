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
-(NSString *)adUnitIdentifier {
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
-(MAAdWaterfallInfo *)waterfall {
    return _simWaterfall;
}
+ (SMAAdWaterfallInfo * _Nonnull)GetWaterfall:(NSString *)name testName:(NSString *)testName responses:(NSArray<NSNumber *> * _Nonnull) responses {
    return [SMAAdWaterfallInfo create: name testName: testName responses: responses];
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

@implementation SMAMediatedNetworkInfo : MAMediatedNetworkInfo
+ (SMAMediatedNetworkInfo * _Nonnull)create:(NSString * _Nonnull)name {
    SMAMediatedNetworkInfo * mediatedNetworkInfo = [SMAMediatedNetworkInfo alloc];
    mediatedNetworkInfo.simName = name;
    return mediatedNetworkInfo;
}
-(NSString *)name {
    return _simName;
}
@end

@implementation SMANetworkResponseInfo : MANetworkResponseInfo
-(MAMediatedNetworkInfo *)mediatedNetwork {
    return _simMediatedNetwork;
}
-(MAAdLoadState)adLoadState {
    return _simAdLoadState;
}
-(BOOL)bidding {
    return _simBidding;
}
-(NSTimeInterval)latency {
    return _simLatency;
}
-(MAError *)error {
    return _simError;
}
@end

@implementation SMAAdWaterfallInfo : MAAdWaterfallInfo
-(NSString *)name {
    return _simName;
}
-(NSString *)testName {
    return _simTestName;
}
-(NSArray<MANetworkResponseInfo *> *)networkResponses {
    return _simNetworkResponses;
}
+ (SMAAdWaterfallInfo * _Nonnull)create:(NSString *_Nonnull)name testName:(NSString *_Nonnull)testName responses:(NSArray<NSNumber *> * _Nonnull) responses {
    SMAAdWaterfallInfo * waterfallInfo = [SMAAdWaterfallInfo alloc];
    waterfallInfo.simName = name;
    waterfallInfo.simTestName = testName;
    NSMutableArray<SMANetworkResponseInfo *> *array = [NSMutableArray arrayWithCapacity: responses.count];
    for (int i = 0; i < responses.count; i++) {
        MAAdLoadState loadState = (MAAdLoadState) [responses[i] intValue];
        SMANetworkResponseInfo * ri = [SMANetworkResponseInfo alloc];
        ri.simMediatedNetwork = [SMAMediatedNetworkInfo create: [NSString stringWithFormat:@"simulator network %d", i]];
        ri.simAdLoadState = loadState;
        ri.simBidding = true;
        ri.simLatency = 12;
        ri.simError = nil;
        if (loadState == MAAdLoadStateAdFailedToLoad) {
            ri.simError = [SMAError create: 321 message: @"simulator error"];
        }
        array[i] = ri;
    }
    waterfallInfo.simNetworkResponses = [array copy];
    return waterfallInfo;
}
@end

@implementation SMAError : MAError
+ (SMAError * _Nonnull)create:(NSInteger)status message:(NSString * _Nonnull)message {
    SMAError *error = [SMAError alloc];
    error.status = (int)status;
    error.simMessage = message;
    return error;
}
-(MAErrorCode)code {
    return _status == 2 ? MAErrorCodeNoFill : MAErrorCodeUnspecified;
}
-(NSString *)message {
    return _simMessage;
}
-(MAAdWaterfallInfo *)waterfall {
    return _simWaterfall;
}
-(NSTimeInterval)requestLatency {
    return _simRequestLatency;
}
@end
