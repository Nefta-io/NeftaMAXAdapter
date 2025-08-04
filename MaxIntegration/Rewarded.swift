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
    private let TimeoutInSeconds = 5
    
    private var _rewarded: MARewardedAd?
    private var _usedInsight: AdInsight?
    private var _consecutiveAdFails = 0
    private var _isLoading = false
    
    private let _viewController: ViewController
    private let _loadButton: UIButton
    private let _showButton: UIButton
    
    private func GetInsightsAndLoad() {
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, callback: Load, timeout: TimeoutInSeconds)
    }
    
    private func Load(insights: Insights) {
        var selectedAdUnitId = DefaultAdUnitId
        _usedInsight = insights._rewarded
        if let usedInsight = _usedInsight, let recommendedAdUnit = usedInsight._adUnit {
            selectedAdUnitId = recommendedAdUnit
        }
        let adUnitToLoad = selectedAdUnitId
        
        Log("Loading \(selectedAdUnitId) insights: \(String(describing: _usedInsight))")
        _rewarded = MARewardedAd.shared(withAdUnitIdentifier: adUnitToLoad)
        _rewarded!.delegate = self
        _rewarded!.setExtraParameterForKey("disable_auto_retries", value: "true")
        _rewarded!.load()
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        ALNeftaMediationAdapter.onExternalMediationRequestFail(.rewarded, adUnitIdentifier: adUnitIdentifier, usedInsight: _usedInsight, error: error)
        
        
        Log("didFailToLoadAd \(adUnitIdentifier): \(error)")
        
        _consecutiveAdFails += 1
        // As per MAX recommendations, retry with exponentially higher delays up to 64s
        // In case you would like to customize fill rate / revenue please contact our customer support
        let delayInSeconds = [0, 2, 4, 8, 16, 32, 64][min(_consecutiveAdFails, 6)]
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayInSeconds)) {
            if self._isLoading {
                self.GetInsightsAndLoad()
            }
        }
    }
    
    func didLoad(_ ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationRequestLoad(.rewarded, ad: ad, usedInsight: _usedInsight)
        
        Log("didLoad \(ad) at: \(ad.revenue)")
        
        _consecutiveAdFails = 0
        SetLoadingButton(isLoading: false)
        _loadButton.isEnabled = false
        _showButton.isEnabled = true
    }
    
    func didPayRevenue(for ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
        
        Log("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue)")
    }
    
    init(viewController: ViewController, loadButton: UIButton, showButton: UIButton, status: UILabel) {
        _viewController = viewController
        _loadButton = loadButton
        _showButton = showButton
        
        super.init()
        
        _loadButton.addTarget(self, action: #selector(OnLoadClick), for: .touchUpInside)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadClick() {
        if _isLoading {
            SetLoadingButton(isLoading: false)
        } else {
            Log("GetInsightsAndLoad...")
            GetInsightsAndLoad()
            SetLoadingButton(isLoading: true)
        }
    }
    
    @objc private func OnShowClick() {
        _rewarded!.show()
        
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
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        Log("didFail \(ad)")
    }

    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        Log("didRewardUser \(ad) \(reward)")
    }
    
    private func Log(_ log: String) {
        _viewController.Log(type: 3, log: log)
    }
    
    private func SetLoadingButton(isLoading: Bool) {
        _isLoading = isLoading
        if isLoading {
            _loadButton.setTitle("Cancel", for: .normal)
        } else {
            _loadButton.setTitle("Load Interstitial", for: .normal)
        }
    }
}
