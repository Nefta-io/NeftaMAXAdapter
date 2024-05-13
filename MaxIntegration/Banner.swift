//
//  Banner.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Banner : NSObject, MAAdViewAdDelegate {
    
    var adView: MAAdView!
    
    func show(view: UIView) {
        adView = MAAdView(adUnitIdentifier: "34686daf09e9b052")
        adView.delegate = self

        let height: CGFloat = 50
        let width: CGFloat = UIScreen.main.bounds.width
        adView.frame = CGRect(x: 0, y: 60, width: width, height: height)
        //adView.backgroundColor = BACKGROUND_COLOR
        view.addSubview(adView)
        adView.loadAd()
    }
    
    func close() {
        adView.removeFromSuperview()
        adView.delegate = nil
        adView = nil
    }
    
    func didLoad(_ ad: MAAd) {
        print("didLoad \(ad)")
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        print("didFailToLoadAd \(adUnitIdentifier): \(error)")
    }

    func didClick(_ ad: MAAd) {
        print("didClick \(ad)")
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        print("didFail \(ad)")
    }

    func didExpand(_ ad: MAAd) {
        print("didExpand \(ad)")
    }

    func didCollapse(_ ad: MAAd) {
        print("didCollapse \(ad)")
    }
    
    func didDisplay(_ ad: MAAd) {
        print("didDisplay \(ad)")
    }
    
    func didHide(_ ad: MAAd) {
        print("didHide \(ad)")
    }
    
    func didPayRevenue(for ad: MAAd) {
        print("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
}
