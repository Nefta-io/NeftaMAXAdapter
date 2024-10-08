//
//  RewardedVideo.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class RewardedVideo : NSObject, MARewardedAdDelegate {
    let _loadButton: UIButton
    let _showButton: UIButton
    let _status: UILabel
    
    var _rewarded: MARewardedAd!

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
        _rewarded = MARewardedAd.shared(withAdUnitIdentifier: "e0b0d20088d60ec5")
        _rewarded.delegate = self
        _rewarded.load()
    }
    
    @objc func Show() {
        _rewarded.show()
        
        _showButton.isEnabled = false
    }
    
    func didLoad(_ ad: MAAd) {
        SetInfo("didLoad \(ad)")
        
        _showButton.isEnabled = true
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

    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        SetInfo("didRewardUser \(ad)")
    }
    
    func didPayRevenue(for ad: MAAd) {
        SetInfo("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
