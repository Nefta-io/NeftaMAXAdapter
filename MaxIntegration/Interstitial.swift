//
//  Interstitial.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Interstitial : NSObject, MAAdDelegate {
    
    var interstitialAd: MAInterstitialAd!
    
    func show() {
        interstitialAd = MAInterstitialAd(adUnitIdentifier: "6d318f954e2630a8")
        interstitialAd.delegate = self
        interstitialAd.load()
    }

    func didLoad(_ ad: MAAd) {
        print("didLoad \(ad)")
        
        interstitialAd.show()
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
    
    func didPayRevenue(for ad: MAAd) {
        print("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
}
