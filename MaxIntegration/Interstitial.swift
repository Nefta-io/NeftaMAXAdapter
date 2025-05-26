//
//  Interstitial.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Interstitial : NSObject, MAAdDelegate, MAAdRevenueDelegate {
    
    private let DefaultAdUnitId = "6d318f954e2630a8"
    
    private let AdUnitIdInsightName = "recommended_interstitial_ad_unit_id"
    private let FloorPriceInsightName = "calculated_user_floor_price_interstitial"
    
    private var _interstitial: MAInterstitialAd?
    private var _recommendedAdUnitId: String?
    private var _calculatedBidFloor: Double = 0.0
    private var _isLoadRequested = false
    private var _consecutiveAdFails = 0
    
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
        if let recommendedAdUnitInsight = insights[AdUnitIdInsightName] {
            _recommendedAdUnitId = recommendedAdUnitInsight._string
        }
        if let floorPriceInsight = insights[FloorPriceInsightName] {
            _calculatedBidFloor = floorPriceInsight._float
        }
        
        print("OnBehaviourInsight for Interstitial recommended AdUnit: \(String(describing: _recommendedAdUnitId)) calculated bid floor:\(_calculatedBidFloor)")

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
        _interstitial = MAInterstitialAd(adUnitIdentifier: adUnitId)
        _interstitial!.delegate = self
        _interstitial!.load()
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        ALNeftaMediationAdapter.onExternalMediationRequestFail(.interstitial, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, adUnitIdentifier: adUnitIdentifier, error: error)
        
        SetInfo("didFailToLoadAd \(adUnitIdentifier): \(error)")
        
        _consecutiveAdFails += 1
        // As per MAX recommendations, retry with exponentially higher delays up to 64s
        // In case you would like to customize fill rate / revenue please contact our customer support
        DispatchQueue.main.asyncAfter(deadline: .now() + [0, 2, 4, 8, 32, 64][min(_consecutiveAdFails, 5)]) {
            self.GetInsightsAndLoad()
        }
    }
    
    func didLoad(_ ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationRequestLoad(.interstitial, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, ad: ad)
        
        SetInfo("didLoad \(ad) at: \(ad.revenue)")
        
        _consecutiveAdFails = 0
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
        _interstitial!.show()
        
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
    
    func didPayRevenue(for ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
        
        SetInfo("didPayRevenueForAd \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
    
    private func SetInfo(_ info: String) {
        print("Integration Interstitial: \(info)")
        _status.text = info
    }
}
