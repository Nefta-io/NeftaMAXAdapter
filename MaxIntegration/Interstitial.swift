//
//  Interstitial.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Interstitial : NSObject, MAAdDelegate {
    
    let _loadButton: UIButton
    let _showButton: UIButton
    let _status: UILabel
    
    var interstitialAd: MAInterstitialAd!
    
    init(loadButton: UIButton, showButton: UIButton, status: UILabel) {
        _loadButton = loadButton
        _showButton = showButton
        _status = status
        
        super.init()
        
        _loadButton.addTarget(self, action: #selector(Load), for: .touchUpInside)
        _showButton.addTarget(self, action: #selector(Show), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc func Load() {
        interstitialAd = MAInterstitialAd(adUnitIdentifier: "e5dc3548d4a0913f")
        interstitialAd.delegate = self
        interstitialAd.load()
    }
    
    @objc func Show() {
        _showButton.isEnabled = false
        interstitialAd.show()
    }

    func didLoad(_ ad: MAAd) {
        _showButton.isEnabled = true
        SetInfo("didLoad \(ad)")
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        SetInfo("didFailToLoadAd \(adUnitIdentifier): \(error)")
    }

    func didDisplay(_ ad: MAAd) {
        SetInfo("didDisplay \(ad)")
    }

    func didClick(_ ad: MAAd) {
        SetInfo("didClick \(ad)")
    }

    func didHide(_ ad: MAAd) {
        SetInfo("didHide \(ad)")
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        SetInfo("didFail \(ad)")
    }
    
    func didPayRevenue(for ad: MAAd) {
        SetInfo("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
