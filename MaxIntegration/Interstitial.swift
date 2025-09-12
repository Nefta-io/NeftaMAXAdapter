//
//  Interstitial.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Interstitial : NSObject, MAAdDelegate, MAAdRevenueDelegate {
    private let DynamicAdUnitId = "e5dc3548d4a0913f"
    private let DefaultAdUnitId = "6d318f954e2630a8"
    private let TimeoutInSeconds = 5
    
    private var _dynamicInterstitial: MAInterstitialAd?
    private var _dynamicAdRevenue: Float64 = -1
    private var _dynamicInsight: AdInsight?
    private var _consecutiveDynamicFails = 0
    private var _defaultInterstitial: MAInterstitialAd?
    private var _defaultAdRevenue: Float64 = -1
    private var _presentingInterstitial: MAInterstitialAd?
    
    private let _viewController: ViewController
    private let _loadSwitch: UISwitch
    private let _showButton: UIButton
    
    private func StartLoading() {
        if _dynamicInterstitial == nil {
            GetInsightsAndLoad(previousInsight: nil)
        }
        if _defaultInterstitial == nil {
            LoadDefault()
        }
    }
    
    private func GetInsightsAndLoad(previousInsight: AdInsight?) {
        NeftaPlugin._instance.GetInsights(Insights.Interstitial, previousInsight: previousInsight, callback: LoadWithInsights, timeout: TimeoutInSeconds)
    }
    
    private func LoadWithInsights(insights: Insights) {
        _dynamicInsight = insights._interstitial
        if let insight = _dynamicInsight {
            let bidFloorParam = String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), insight._floorPrice)
            
            Log("Loading Dynamic Interstitial with insights: \(insight) floor: \(bidFloorParam)")
            _dynamicInterstitial = MAInterstitialAd(adUnitIdentifier: DynamicAdUnitId)
            _dynamicInterstitial!.delegate = self
            _dynamicInterstitial!.setExtraParameterForKey("disable_auto_retries", value: "true")
            _dynamicInterstitial!.setExtraParameterForKey("jC7Fp", value: bidFloorParam)
            _dynamicInterstitial!.load()
            
            ALNeftaMediationAdapter.onExternalMediationRequest(withInterstitial: _dynamicInterstitial!, insight: insight)
        }
    }
    
    private func LoadDefault() {
        Log("Loading Default Interstitial")
        _defaultInterstitial = MAInterstitialAd(adUnitIdentifier: DefaultAdUnitId)
        _defaultInterstitial!.delegate = self
        _defaultInterstitial!.load()
        
        ALNeftaMediationAdapter.onExternalMediationRequest(withInterstitial: _defaultInterstitial!)
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        if adUnitIdentifier == DynamicAdUnitId {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withInterstitial: _dynamicInterstitial!, error: error)
            
            Log("Load failed Dynamic \(adUnitIdentifier): \(error)")
            
            _dynamicInterstitial = nil
            _consecutiveDynamicFails += 1
            // As per MAX recommendations, retry with exponentially higher delays up to 64s
            // In case you would like to customize fill rate / revenue please contact our customer support
            let delayInSeconds = [0, 2, 4, 8, 16, 32, 64][min(_consecutiveDynamicFails, 6)]
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayInSeconds)) {
                if self._loadSwitch.isOn {
                    self.GetInsightsAndLoad(previousInsight: self._dynamicInsight)
                }
            }
        } else {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withInterstitial: _defaultInterstitial!, error: error)
            
            Log("Load failed Default \(adUnitIdentifier): \(error)")
            
            _defaultInterstitial = nil
            if _loadSwitch.isOn {
                LoadDefault()
            }
        }
    }
    
    func didLoad(_ ad: MAAd) {
        if ad.adUnitIdentifier == DynamicAdUnitId {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withInterstitial: _dynamicInterstitial!, ad: ad)
            
            Log("Load Dynamic \(ad) at: \(ad.revenue)")
            
            _consecutiveDynamicFails = 0
            _dynamicAdRevenue = ad.revenue
        } else {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withInterstitial: _defaultInterstitial!, ad: ad)
            
            Log("Load Dyanmic \(ad) at: \(ad.revenue)")
            
            _defaultAdRevenue = ad.revenue
        }
        
        UpdateShowButton()
    }
    
    func didPayRevenue(for ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
        
        Log("didPayRevenueForAd \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
    
    func didClick(_ ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationClick(ad)
        
        Log("didClick \(ad)")
    }
    
    init(viewController: ViewController, loadSwitch: UISwitch, showButton: UIButton) {
        _viewController = viewController
        _loadSwitch = loadSwitch
        _showButton = showButton
        
        super.init()
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            StartLoading()
        }
    }
    
    @objc private func OnShowClick() {
        var isShown = false
        if _dynamicAdRevenue >= 0 {
            if _defaultAdRevenue > _dynamicAdRevenue {
                isShown = TryShowDefault()
            }
            if !isShown {
                isShown = TryShowDynamic()
            }
        }
        if !isShown && _defaultAdRevenue >= 0 {
            isShown = TryShowDefault()
        }
        
        UpdateShowButton()
    }
    
    private func TryShowDynamic() -> Bool {
        var isShown = false
        if _dynamicInterstitial!.isReady {
            _dynamicInterstitial!.show()
            isShown = true
        }
        _dynamicAdRevenue = -1
        _presentingInterstitial = _dynamicInterstitial
        _dynamicInterstitial = nil
        return isShown
    }
    
    private func TryShowDefault() -> Bool {
        var isShown = false
        if _defaultInterstitial!.isReady {
            _defaultInterstitial!.show()
            isShown = true
        }
        _defaultAdRevenue = -1
        _presentingInterstitial = _defaultInterstitial
        _defaultInterstitial = nil
        return isShown
    }

    func didDisplay(_ ad: MAAd) {
        Log("didDisplay \(ad)")
        _viewController.OnFullScreenAdDisplay(displayed: true)
    }

    func didHide(_ ad: MAAd) {
        Log("didHide \(ad)")
        _viewController.OnFullScreenAdDisplay(displayed: false)
        _presentingInterstitial = nil
        
        // start new cycle
        if _loadSwitch.isOn {
            StartLoading()
        }
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        Log("didFail \(ad)")
    }
    
    func UpdateShowButton() {
        _showButton.isEnabled = _dynamicAdRevenue >= 0 || _defaultAdRevenue >= 0
    }
    
    private func Log(_ log: String) {
        _viewController.Log(type: 2, log: log)
    }
}
