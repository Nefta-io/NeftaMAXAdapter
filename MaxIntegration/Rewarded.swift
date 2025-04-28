//
//  Rewarded.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Rewarded : NSObject, MARewardedAdDelegate {
    
    private let _defaultAdUnitId = "918acf84edf9c034"
    
    static let InsightAdUnitId = "recommended_rewarded_ad_unit_id"
    static let InsightFloorPrice = "calculated_user_floor_price_rewarded"
    
    private var RequestNewInsights: () -> Void
    private var _selectedAdUnitId: String?
    private var _recommendedAdUnitId: String?
    private var _calculatedBidFloor: Double = 0.0
    private var _consecutiveAdFail = 0
    private var _isLoadPending = false
    
    private let _loadButton: UIButton
    private let _showButton: UIButton
    private let _status: UILabel
    private let _onFullScreenAdDisplayed: (Bool) -> Void
    
    var _rewarded: MARewardedAd!
    
    func OnBehaviourInsight(insights: [String: Insight]) {
        _recommendedAdUnitId = insights[Rewarded.InsightAdUnitId]?._string
        _calculatedBidFloor = insights[Rewarded.InsightFloorPrice]?._float ?? 0.0
        
        print("OnBehaviourInsight for Rewarded recommended AdUnit: \(String(describing: _recommendedAdUnitId))/cpm:\(_calculatedBidFloor)")
        
        _selectedAdUnitId = _recommendedAdUnitId

        if _isLoadPending {
            Load()
        }
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        ALNeftaMediationAdapter.onExternalMediationRequestFail(.rewarded, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, adUnitIdentifier: adUnitIdentifier, error: error)
        
        if error.code == .noFill {
            _consecutiveAdFail += 1
            if _consecutiveAdFail == 1 { // in case of first no fill, try to get new insight (will probably return adUnit with lower bid floor
                _isLoadPending = true
                RequestNewInsights()
            } else { // for consequential no fills go with default (no bid floor) ad unit
                _selectedAdUnitId = nil
                Load()
            }
        }
        
        SetInfo("didFailToLoadAd \(adUnitIdentifier): \(error)")
    }
    
    func didLoad(_ ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationRequestLoad(.rewarded, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, ad: ad)
        
        _consecutiveAdFail = 0
        // Optionally request new insights on ad load, in case ad unit with higher bid floor gets recommended
        // SelectAdUnitFromInsights()
        
        SetInfo("didLoad \(ad)")
        _showButton.isEnabled = true
    }
    
    init(requestNewInsights: @escaping (() -> Void), loadButton: UIButton, showButton: UIButton, status: UILabel, onDisplay: @escaping (Bool) -> Void) {
        RequestNewInsights = requestNewInsights
        _loadButton = loadButton
        _showButton = showButton
        _status = status
        _onFullScreenAdDisplayed = onDisplay
        
        super.init()
        
        _loadButton.addTarget(self, action: #selector(Load), for: .touchUpInside)
        _showButton.addTarget(self, action: #selector(Show), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc func Load() {
        _rewarded = MARewardedAd.shared(withAdUnitIdentifier: _selectedAdUnitId ?? _defaultAdUnitId)
        _rewarded.delegate = self
        _rewarded.load()
    }
    
    @objc func Show() {
        _rewarded.show()
        
        _showButton.isEnabled = false
    }

    func didDisplay(_ ad: MAAd) {
        SetInfo("didDisplay \(ad)")
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
        _onFullScreenAdDisplayed(true)
    }

    func didClick(_ ad: MAAd) {
        SetInfo("didClick \(ad)")
    }

    func didHide(_ ad: MAAd) {
        SetInfo("didHide \(ad)")
        _onFullScreenAdDisplayed(false)
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        SetInfo("didFail \(ad)")
    }

    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        SetInfo("didRewardUser \(ad) \(reward)")
    }
    
    func didPayRevenue(for ad: MAAd) {
        SetInfo("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
