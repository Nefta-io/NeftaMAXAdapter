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
    
    private var _defaultInterstitial: MAInterstitialAd?
    private var _defaultAd: MAAd?
    private var _recommendedInterstitial: MAInterstitialAd?
    private var _recommendedAd: MAAd?
    
    private var _recommendedAdUnitId: String?
    private var _calculatedBidFloor: Double = 0.0
    
    private let _loadButton: UIButton
    private let _showButton: UIButton
    private let _status: UILabel
    private let _onFullScreenAdDisplayed: (Bool) -> Void
    
    func Load() {
        SetInfo("Load default: \(String(describing: _defaultAd)) recommended: \(String(describing: _recommendedInterstitial))")
        
        if _defaultAd == nil {
            _defaultInterstitial = MAInterstitialAd(adUnitIdentifier: DefaultAdUnitId)
            _defaultInterstitial!.delegate = self
            _defaultInterstitial!.revenueDelegate = self
            _defaultInterstitial!.load()
        }
        
        if _recommendedAd == nil {
            NeftaPlugin._instance.GetBehaviourInsight([AdUnitIdInsightName, FloorPriceInsightName], callback: OnBehaviourInsight)
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
        
        print("OnBehaviourInsight for Interstitial: \(String(describing: _recommendedAdUnitId)) calculated bid floor: \(_calculatedBidFloor)")
        
        if let recommendedAdUnitId = _recommendedAdUnitId, DefaultAdUnitId != recommendedAdUnitId {
            _recommendedInterstitial = MAInterstitialAd(adUnitIdentifier: recommendedAdUnitId)
            _recommendedInterstitial!.delegate = self
            _recommendedInterstitial!.revenueDelegate = self
            _recommendedInterstitial!.load()
        }
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        if adUnitIdentifier == _recommendedAdUnitId {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(.interstitial, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, adUnitIdentifier: adUnitIdentifier, error: error)
            
            _recommendedInterstitial = nil
            _recommendedAdUnitId = nil
            _calculatedBidFloor = 0
        } else {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(.interstitial, recommendedAdUnitId: nil, calculatedFloorPrice: 0, adUnitIdentifier: adUnitIdentifier, error: error)
            
            _defaultInterstitial = nil
        }
        
        // or automatically retry
        //if _recommendedInterstitial == nil && _defaultInterstitial == nil {
        //    Load()
        //}
        
        SetInfo("didFailToLoadAd \(adUnitIdentifier): \(error)")
    }
    
    func didLoad(_ ad: MAAd) {
        if ad.adUnitIdentifier == _recommendedAdUnitId {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(.interstitial, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, ad: ad)
            
            _recommendedAd = ad
        } else {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(.interstitial, recommendedAdUnitId: nil, calculatedFloorPrice: 0, ad: ad)
            
            _defaultAd = ad
        }
        
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
        Load()
    }
    
    @objc func OnShowClick() {
        SetInfo("Show default: \(String(describing: _defaultAd)) recommended: \(String(describing: _recommendedInterstitial))")
        
        if _recommendedAd != nil {
            if _defaultAd != nil && _defaultAd!.revenue > _recommendedAd!.revenue {
                _defaultInterstitial!.show()
                _defaultInterstitial = nil
                _defaultAd = nil
            } else {
                _recommendedInterstitial!.show()
                _recommendedInterstitial = nil
                _recommendedAd = nil
            }
        } else if _defaultAd != nil {
            _defaultInterstitial!.show()
            _defaultInterstitial = nil
            _defaultAd = nil
        }
        
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
