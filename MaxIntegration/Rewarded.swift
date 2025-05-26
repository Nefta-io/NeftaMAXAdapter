//
//  Rewarded.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Rewarded : NSObject, MARewardedAdDelegate, MAAdRevenueDelegate {
    
    private let DefaultAdUnitId = "918acf84edf9c034"
    
    private let AdUnitIdInsightName = "recommended_rewarded_ad_unit_id"
    private let FloorPriceInsightName = "calculated_user_floor_price_rewarded"
    
    private var _rewarded: MARewardedAd?
    private var _recommendedAdUnitId: String?
    private var _calculatedBidFloor: Double = 0.0
    private var _isLoadRequested = false
    
    private let _loadButton: UIButton
    private let _showButton: UIButton
    private let _status: UILabel
    private let _onFullScreenAdDisplayed: (Bool) -> Void
    
    private func GetInsightsAndLoad() {
        _isLoadRequested = true
        
        NeftaPlugin._instance.GetBehaviourInsight([AdUnitIdInsightName, FloorPriceInsightName], callback: OnBehaviourInsight)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self._isLoadRequested {
                self._recommendedAdUnitId = nil
                self._calculatedBidFloor = 0
                self.Load()
            }
        }
    }
    
    func OnBehaviourInsight(insights: [String: Insight]) {
        _recommendedAdUnitId = nil
        _calculatedBidFloor = 0
        if let recommendedInsight = insights[AdUnitIdInsightName] {
            _recommendedAdUnitId = recommendedInsight._string
        }
        if let bidFloorInsight = insights[FloorPriceInsightName] {
            _calculatedBidFloor = bidFloorInsight._float
        }
        
        print("OnBehaviourInsight for Rewarded: \(String(describing: _recommendedAdUnitId)) calculated bid floor: \(_calculatedBidFloor)")
        
        if _isLoadRequested {
            Load()
        }
    }
    
    private func Load() {
        _isLoadRequested = false
        
        var adUnitId = DefaultAdUnitId
        if let recommendedAdUnitId = _recommendedAdUnitId, !recommendedAdUnitId.isEmpty {
            adUnitId = recommendedAdUnitId
        }
        _rewarded = MARewardedAd.shared(withAdUnitIdentifier: adUnitId)
        _rewarded!.delegate = self
        _rewarded!.load()
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        ALNeftaMediationAdapter.onExternalMediationRequestFail(.rewarded, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, adUnitIdentifier: adUnitIdentifier, error: error)
        
        SetInfo("didFailToLoadAd \(adUnitIdentifier): \(error)")
        
        // or automatically retry with a delay
        // DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        //     self.GetInsightsAndLoad()
        // }
    }
    
    func didLoad(_ ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationRequestLoad(.rewarded, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, ad: ad)
        
        SetInfo("didLoad \(ad) at: \(ad.revenue)")
        
        _showButton.isEnabled = true
    }
    
    init(loadButton: UIButton, showButton: UIButton, status: UILabel, onDisplay: @escaping (Bool) -> Void) {
        _loadButton = loadButton
        _showButton = showButton
        _status = status
        _onFullScreenAdDisplayed = onDisplay
        
        super.init()
        
        _loadButton.addTarget(self, action: #selector(OnLoadClick), for: .touchUpInside)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc func OnLoadClick() {
        GetInsightsAndLoad()
    }
    
    @objc func OnShowClick() {
        _rewarded!.show()
        
        _showButton.isEnabled = false
    }

    func didDisplay(_ ad: MAAd) {
        SetInfo("didDisplay \(ad)")
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
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
        
        SetInfo("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
    
    private func SetInfo(_ info: String) {
        print("Integration Rewarded: \(info)")
        _status.text = info
    }
}
