//
//  Rewarded.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Rewarded : NSObject, MARewardedAdDelegate, MAAdRevenueDelegate {
    private let DynamicAdUnitId = "e0b0d20088d60ec5"
    private let DefaultAdUnitId = "918acf84edf9c034"
    private let TimeoutInSeconds = 5
    
    private var _dynamicRewarded: MARewardedAd?
    private var _isDynamicLoaded = false
    private var _dynamicAdUnitInsight: AdInsight?
    private var _consecutiveDynamicBidAdFails = 0
    private var _defaultRewarded: MARewardedAd?
    private var _isDefaultLoaded = false
    
    private let _viewController: ViewController
    private let _loadSwitch: UISwitch
    private let _showButton: UIButton
    
    private func StartLoading() {
        if _dynamicRewarded == nil {
            GetInsightsAndLoad()
        }
        if _defaultRewarded == nil {
            LoadDefault()
        }
    }
    
    private func GetInsightsAndLoad() {
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, callback: LoadWithInsights, timeout: TimeoutInSeconds)
    }
    
    private func LoadWithInsights(insights: Insights) {
        if let insight = insights._rewarded {
            _dynamicAdUnitInsight = insight
            let bidFloor = String(format: "%.10f", insight._floorPrice)
            
            Log("Loading Dynamic with floor: \(bidFloor)")
            _dynamicRewarded = MARewardedAd.shared(withAdUnitIdentifier: DynamicAdUnitId)
            _dynamicRewarded!.delegate = self
            _dynamicRewarded!.setExtraParameterForKey("disable_auto_retries", value: "true")
            _dynamicRewarded!.setExtraParameterForKey("jC7Fp", value: bidFloor)
            _dynamicRewarded!.load()
        }
    }
    
    private func LoadDefault() {
        Log("Loading Default")
        _defaultRewarded = MARewardedAd.shared(withAdUnitIdentifier: DefaultAdUnitId)
        _defaultRewarded!.delegate = self
        _defaultRewarded!.load()
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        if adUnitIdentifier == DynamicAdUnitId {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(.rewarded, adUnitIdentifier: adUnitIdentifier, usedInsight: _dynamicAdUnitInsight, error: error)
            
            Log("Load failed Dynamic \(adUnitIdentifier): \(error)")
            
            _dynamicRewarded = nil
            _consecutiveDynamicBidAdFails += 1
            // As per MAX recommendations, retry with exponentially higher delays up to 64s
            // In case you would like to customize fill rate / revenue please contact our customer support
            let delayInSeconds = [0, 2, 4, 8, 16, 32, 64][min(_consecutiveDynamicBidAdFails, 6)]
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayInSeconds)) {
                if self._loadSwitch.isOn {
                    self.GetInsightsAndLoad()
                }
            }
        } else {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(.rewarded, adUnitIdentifier: adUnitIdentifier, usedInsight: nil, error: error)
            
            Log("Load failed Default \(adUnitIdentifier): \(error)")
            
            _defaultRewarded = nil
            if _loadSwitch.isOn {
                LoadDefault()
            }
        }
    }
    
    func didLoad(_ ad: MAAd) {
        if ad.adUnitIdentifier == DynamicAdUnitId {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(.rewarded, ad: ad, usedInsight: _dynamicAdUnitInsight)
            
            Log("Loaded Dyanamic \(ad) at: \(ad.revenue)")
            
            _consecutiveDynamicBidAdFails = 0
            _isDynamicLoaded = true
        } else {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(.rewarded, ad: ad, usedInsight: nil)
            
            Log("Loaded Default \(ad) at: \(ad.revenue)")
            
            _isDefaultLoaded = true
        }
        
        UpdateShowButton()
    }
    
    func didPayRevenue(for ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
        
        Log("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue)")
    }
    
    init(viewController: ViewController, loadSwitch: UISwitch, showButton: UIButton, status: UILabel) {
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
        if _isDynamicLoaded {
            if _dynamicRewarded!.isReady {
                _dynamicRewarded!.show()
                isShown = true
            }
            _isDynamicLoaded = false
            _dynamicRewarded = nil
        }
        if !isShown && _isDefaultLoaded {
            if _defaultRewarded!.isReady {
                _defaultRewarded!.show()
            }
            _isDefaultLoaded = false
            _defaultRewarded = nil
        }
        
        UpdateShowButton()
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
        
        // start new load cycle
        if _loadSwitch.isOn {
            StartLoading()
        }
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        Log("didFail \(ad)")
    }

    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        Log("didRewardUser \(ad) \(reward)")
    }
    
    func UpdateShowButton() {
        _showButton.isEnabled = _isDynamicLoaded || _isDefaultLoaded
    }
    
    private func Log(_ log: String) {
        _viewController.Log(type: 3, log: log)
    }
}
