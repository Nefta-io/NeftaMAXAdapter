//
//  RewardedVideo.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class RewardedVideo : NSObject, MARewardedAdDelegate {
    var rewardedAd: MARewardedAd!
    
    func show() {
        rewardedAd = MARewardedAd.shared(withAdUnitIdentifier: "e0b0d20088d60ec5")
        rewardedAd.delegate = self
        rewardedAd.load()
    }
    
    func didLoad(_ ad: MAAd) {
        print("didLoad \(ad)")
        
        rewardedAd.show()
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        print("didFailToLoadAd \(adUnitIdentifier): \(error)")
    }

    func didDisplay(_ ad: MAAd) {
        print("didDisplay \(ad)")
    }

    func didClick(_ ad: MAAd) {
        print("didClick \(ad)")
    }

    func didHide(_ ad: MAAd) {
        print("didHide \(ad)")
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        print("didFail \(ad)")
    }

    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        print("didRewardUser \(ad)")
    }
    
    func didPayRevenue(for ad: MAAd) {
        print("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
}
