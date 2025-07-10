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
    private let TimeoutInSeconds = 5
    
    private var _interstitial: MAInterstitialAd?
    private var _usedInsight: AdInsight?
    private var _consecutiveAdFails = 0
    
    private let _viewController: ViewController
    private let _loadButton: UIButton
    private let _showButton: UIButton
    
    private func GetInsightsAndLoad() {
        NeftaPlugin._instance.GetInsights(Insights.Interstitial, callback: Load, timeout: TimeoutInSeconds)
    }
    
    private func Load(insights: Insights) {
        var selectedAdUnitId = DefaultAdUnitId
        _usedInsight = insights._interstitial
        if let usedInsight = _usedInsight, let recommendedAdUnit = usedInsight._adUnit {
            selectedAdUnitId = recommendedAdUnit
        }
        
        Log("Loading \(selectedAdUnitId) insights: \(String(describing: _usedInsight))")
        _interstitial = MAInterstitialAd(adUnitIdentifier: selectedAdUnitId)
        _interstitial!.delegate = self
        _interstitial!.setExtraParameterForKey("disable_auto_retries", value: "true")
        _interstitial!.load()
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        ALNeftaMediationAdapter.onExternalMediationRequestFail(.interstitial, adUnitIdentifier: adUnitIdentifier, usedInsight: _usedInsight, error: error)
        
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
        ALNeftaMediationAdapter.onExternalMediationRequestLoad(.interstitial, ad: ad, usedInsight: _usedInsight)
        
        Log("didLoad \(ad) at: \(ad.revenue)")
        
        _consecutiveAdFails = 0
        _showButton.isEnabled = true
    }
    
    func didPayRevenue(for ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
        
        Log("didPayRevenueForAd \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
    
    init(viewController: ViewController, loadButton: UIButton, showButton: UIButton) {
        _viewController = viewController
        _loadButton = loadButton
        _showButton = showButton
        
        super.init()
        
        _loadButton.addTarget(self, action: #selector(OnLoadClick), for: .touchUpInside)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadClick() {
        Log("GetInsightsAndLoad...")
        GetInsightsAndLoad()
        _loadButton.isEnabled = false
    }
    
    @objc private func OnShowClick() {
        _interstitial!.show()
        
        _showButton.isEnabled = false
    }

    func didDisplay(_ ad: MAAd) {
        Log("didDisplay \(ad)")
        _viewController.OnFullScreenAdDisplay(displayed: true)
    }

    func didClick(_ ad: MAAd) {
        Log("didClick \(ad)")
    }

    func didHide(_ ad: MAAd) {
        Log("didHide \(ad)")
        _viewController.OnFullScreenAdDisplay(displayed: false)
        _loadButton.isEnabled = true
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        Log("didFail \(ad)")
    }
    
    private func Log(_ log: String) {
        _viewController.Log(type: 2, log: log)
    }
}
