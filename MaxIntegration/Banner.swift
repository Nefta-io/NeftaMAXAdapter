//
//  Banner.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Banner : NSObject, MAAdViewAdDelegate {
    private let DefaultAdUnitId = "34686daf09e9b052"
    private let AdUnitIdInsightName = "recommended_banner_ad_unit_id"
    private let FloorPriceInsightName = "calculated_user_floor_price_banner"
    
    private var _recommendedAdUnitId: String?
    private var _calculatedBidFloor: Double = 0.0
    private var _isLoadRequested = false
    
    private let _showButton: UIButton
    private let _hideButton: UIButton
    private let _status: UILabel
    private let _bannerPlaceholder: UIView
    
    private var _adView: MAAdView!
    
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
    
    private func OnBehaviourInsight(insights: [String: Insight]) {
        _recommendedAdUnitId = nil
        _calculatedBidFloor = 0
        if let recommendedAdUnitInsight = insights[AdUnitIdInsightName] {
            _recommendedAdUnitId = recommendedAdUnitInsight._string
        }
        if let bidFloorInsight = insights[FloorPriceInsightName] {
            _calculatedBidFloor = bidFloorInsight._float
        }
        
        print("OnBehaviourInsight for Banner: \(String(describing: _recommendedAdUnitId)), calculated bid floor: \(_calculatedBidFloor)")
        
        if _isLoadRequested {
            Load()
        }
    }
    
    func Load() {
        _isLoadRequested = false
        
        var adUnitId = DefaultAdUnitId
        if let recommendedAdUnitId = _recommendedAdUnitId {
            adUnitId = recommendedAdUnitId
        }
        _adView = MAAdView(adUnitIdentifier: adUnitId)
        _adView.delegate = self

        _adView.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
        _bannerPlaceholder.addSubview(_adView)
        _adView.loadAd()
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        ALNeftaMediationAdapter.onExternalMediationRequestFail(.banner, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, adUnitIdentifier: adUnitIdentifier, error: error)
        
        SetInfo("didFailToLoadAd \(adUnitIdentifier): \(error)")
        
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
    }
    
    func didLoad(_ ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationRequestLoad(.banner, recommendedAdUnitId: _recommendedAdUnitId, calculatedFloorPrice: _calculatedBidFloor, ad: ad)
        
        SetInfo("didLoad \(ad)")
    }
    
    init(showButton: UIButton, hideButton: UIButton, status: UILabel, bannerPlaceholder: UIView) {
        _showButton = showButton
        _hideButton = hideButton
        _status = status
        _bannerPlaceholder = bannerPlaceholder
        
        super.init()
        
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        _hideButton.addTarget(self, action: #selector(OnHideClick), for: .touchUpInside)
        _hideButton.isEnabled = false
    }
    
    func SetAutoRefresh(refresh: Bool) {
        if let adView = _adView {
            if refresh {
                adView.startAutoRefresh()
            } else {
                adView.stopAutoRefresh()
            }
        }
    }

    @objc func OnShowClick() {
        GetInsightsAndLoad()
        
        SetInfo("Loading...")
        
        _showButton.isEnabled = false
        _hideButton.isEnabled = true
    }
    
    @objc func OnHideClick() {
        _adView.removeFromSuperview()
        _adView.delegate = nil
        _adView = nil
        
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
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
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
        
        SetInfo("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
