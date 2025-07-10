//
//  Banner.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Banner : NSObject, MAAdViewAdDelegate, MAAdRevenueDelegate {
    private let DefaultAdUnitId = "34686daf09e9b052"
    private let TimeoutInSeconds = 5
    
    private var _adView: MAAdView!
    private var _usedInsight: AdInsight?
    private var _consecutiveAdFails = 0
    
    private let _viewController: ViewController
    private let _showButton: UIButton
    private let _hideButton: UIButton
    
    private func GetInsightsAndLoad() {
        NeftaPlugin._instance.GetInsights(Insights.Banner, callback: Load, timeout: TimeoutInSeconds)
    }
    
    private func Load(insights: Insights) {
        var selectedAdUnitId = DefaultAdUnitId
        _usedInsight = insights._banner
        if let usedInsight = _usedInsight, let recommendedAdUnit = usedInsight._adUnit {
            selectedAdUnitId = recommendedAdUnit
        }

        Log("Loading \(selectedAdUnitId) insights: \(String(describing: _usedInsight))")
        _adView = MAAdView(adUnitIdentifier: selectedAdUnitId)
        _adView.delegate = self
        _adView.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
        _viewController._bannerPlaceholder.addSubview(self._adView)
        _adView.loadAd()
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        ALNeftaMediationAdapter.onExternalMediationRequestFail(.banner, adUnitIdentifier: adUnitIdentifier, usedInsight: _usedInsight, error: error)
        
        Log("didFailToLoadAd \(adUnitIdentifier): \(error)")
        
        _consecutiveAdFails += 1
        // As per MAX recommendations, retry with exponentially higher delays up to 64s
        // In case you would like to customize fill rate / revenue please contact our customer support
        let delayInSeconds = [0, 2, 4, 8, 16, 32, 64][min(_consecutiveAdFails, 6)]
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayInSeconds)) {
            self.GetInsightsAndLoad()
        }
    }
    
    func didLoad(_ ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationRequestLoad(.banner, ad: ad, usedInsight: _usedInsight)
        
        Log("didLoad \(ad) at: \(ad.revenue)")
        
        _consecutiveAdFails = 0
    }
    
    func didPayRevenue(for ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
        
        Log("didPayRevenueForAd \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
    
    init(viewController: ViewController, showButton: UIButton, hideButton: UIButton) {
        _viewController = viewController
        _showButton = showButton
        _hideButton = hideButton
        
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
        Log("Loading...")
        GetInsightsAndLoad()
        
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
        Log("didClick \(ad)")
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        Log("didFail \(ad)")
    }

    func didExpand(_ ad: MAAd) {
        Log("didExpand \(ad)")
    }

    func didCollapse(_ ad: MAAd) {
        Log("didCollapse \(ad)")
    }
    
    func didDisplay(_ ad: MAAd) {
        Log("didDisplay \(ad)")
    }
    
    func didHide(_ ad: MAAd) {
        Log("didHide \(ad)")
    }
    
    private func Log(_ log: String) {
        _viewController.Log(type: 1, log: log)
    }
}
