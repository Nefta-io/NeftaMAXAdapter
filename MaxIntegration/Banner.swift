//
//  Banner.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Banner : NSObject, MAAdViewAdDelegate {
    
    static let InsightFloorPrice = "calculated_user_floor_price_banner"
    
    private let _adUnits = [
        AdUnit(id: "34686daf09e9b052", cpm: 50.0),
        AdUnit(id: "a843106cd98eb4d1", cpm: 75.0),
        AdUnit(id: "396ac99b5226c18b", cpm: 100.0)
    ]
    
    private var RequestNewInsights: () -> Void
    private var _insights: [String: Insight]?
    private var _selectedAdUnit: AdUnit!
    private var _calculatedBidFloor: Double = 0.0
    private var _consecutiveAdFail = 0
    private var _isLoadPending = false
    
    private let _showButton: UIButton
    private let _hideButton: UIButton
    private let _status: UILabel
    private let _bannerPlaceholder: UIView
    
    private var _adView: MAAdView!
    
    func SelectAdUnitFromInsights() {
        _selectedAdUnit = _adUnits[0]
        
        if let insights = _insights {
            _calculatedBidFloor = insights[Banner.InsightFloorPrice]?._float ?? 0
            
            for adUnit in _adUnits {
                if adUnit._cpm > _calculatedBidFloor {
                    break
                }
                _selectedAdUnit = adUnit
            }
        }
        print("SelectAdUnitFromInsights for Banner: \(_selectedAdUnit!._id)/cpm:\(_selectedAdUnit!._cpm), calculated bid floor: \(_calculatedBidFloor)")
    }
    
    func Load() {
        _adView = MAAdView(adUnitIdentifier: _selectedAdUnit!._id)
        _adView.delegate = self

        _adView.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
        _bannerPlaceholder.addSubview(_adView)
        _adView.loadAd()
        
        _showButton.isEnabled = false
        _hideButton.isEnabled = true
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        ALNeftaMediationAdapter.onExternalMediationRequestFail(.banner, requestedFloorPrice: _selectedAdUnit._cpm, calculatedFloorPrice: _calculatedBidFloor, adUnitIdentifier: adUnitIdentifier, error: error)

        if error.code == .noFill {
            _consecutiveAdFail += 1
            if _consecutiveAdFail > 2 {
                _selectedAdUnit = _adUnits[0]
                Load()
            } else {
                _isLoadPending = true
                RequestNewInsights()
            }
        }
        
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
        SetInfo("didFailToLoadAd \(adUnitIdentifier): \(error)")
    }
    
    func didLoad(_ ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationRequestLoad(.banner, requestedFloorPrice: _selectedAdUnit!._cpm, calculatedFloorPrice: _calculatedBidFloor, ad: ad)
        
        _consecutiveAdFail = 0
        // Optionally try to select adUnit with higher cpm again
        // SelectAdUnitFromInsights()
        
        SetInfo("didLoad \(ad)")
    }
    
    init(requestNewInsights: @escaping (() -> Void), showButton: UIButton, hideButton: UIButton, status: UILabel, bannerPlaceholder: UIView) {
        RequestNewInsights = requestNewInsights
        
        _showButton = showButton
        _hideButton = hideButton
        _status = status
        _bannerPlaceholder = bannerPlaceholder
        
        super.init()
        
        _showButton.addTarget(self, action: #selector(Show), for: .touchUpInside)
        _hideButton.addTarget(self, action: #selector(Hide), for: .touchUpInside)
        _hideButton.isEnabled = false
        
        SelectAdUnitFromInsights()
    }
    
    func OnBehaviourInsight(insights: [String: Insight]) {
        _insights = insights
        
        SelectAdUnitFromInsights()
        
        if _isLoadPending {
            Load()
        }
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

    @objc func Show() {
        Load()
    }
    
    @objc func Hide() {
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
        SetInfo("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
