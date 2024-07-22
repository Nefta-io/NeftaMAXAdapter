//
//  Banner.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Banner : NSObject, MAAdViewAdDelegate {
    
    let _showButton: UIButton
    let _hideButton: UIButton
    let _status: UILabel
    let _bannerPlaceholder: UIView
    
    var _adView: MAAdView!
    
    init(showButton: UIButton, hideButton: UIButton, status: UILabel, bannerPlaceholder: UIView) {
        _showButton = showButton
        _hideButton = hideButton
        _status = status
        _bannerPlaceholder = bannerPlaceholder
        
        super.init()
        
        _showButton.addTarget(self, action: #selector(Show), for: .touchUpInside)
        _hideButton.addTarget(self, action: #selector(Hide), for: .touchUpInside)
        _hideButton.isEnabled = false
    }
    
    @objc func Show() {
        _adView = MAAdView(adUnitIdentifier: "34686daf09e9b052")
        _adView.delegate = self

        _adView.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
        //adView.backgroundColor = BACKGROUND_COLOR
        _bannerPlaceholder.addSubview(_adView)
        _adView.loadAd()
        
        _showButton.isEnabled = false
        _hideButton.isEnabled = true
    }
    
    @objc func Hide() {
        _adView.removeFromSuperview()
        _adView.delegate = nil
        _adView = nil
        
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
    }
    
    func didLoad(_ ad: MAAd) {
        SetInfo("didLoad \(ad)")
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
        SetInfo("didFailToLoadAd \(adUnitIdentifier): \(error)")
    }

    func didClick(_ ad: MAAd) {
        SetInfo("didClick \(ad)")
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        SetInfo("didFail \(ad)")
    }

    func didExpand(_ ad: MAAd) {
        SetInfo("didExpand \(ad)")
    }

    func didCollapse(_ ad: MAAd) {
        SetInfo("didCollapse \(ad)")
    }
    
    func didDisplay(_ ad: MAAd) {
        SetInfo("didDisplay \(ad)")
    }
    
    func didHide(_ ad: MAAd) {
        SetInfo("didHide \(ad)")
    }
    
    func didPayRevenue(for ad: MAAd) {
        SetInfo("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
