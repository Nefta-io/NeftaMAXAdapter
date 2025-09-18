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
    private var _dynamicAdRevenue: Float64 = -1
    private var _dynamicInsight: AdInsight?
    private var _consecutiveDynamicFails = 0
    private var _defaultRewarded: MARewardedAd?
    private var _defaultAdRevenue: Float64 = -1
    
    private let _viewController: ViewController
    private let _loadSwitch: UISwitch
    private let _showButton: UIButton
    private let _status: UILabel
    
    private func StartLoading() {
        if _dynamicRewarded == nil {
            GetInsightsAndLoad(previousInsight: nil)
        }
        if _defaultRewarded == nil {
            LoadDefault()
        }
    }
    
    private func GetInsightsAndLoad(previousInsight: AdInsight?) {
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, previousInsight: previousInsight, callback: LoadWithInsights, timeout: TimeoutInSeconds)
    }
    
    private func LoadWithInsights(insights: Insights) {
        _dynamicInsight = insights._rewarded
        if let insight =  _dynamicInsight {
            let bidFloorParam = String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), insight._floorPrice)
            
            Log("Loading Dynamic Rewarded with insight \(insight) floor: \(bidFloorParam)")
            _dynamicRewarded = MARewardedAd.shared(withAdUnitIdentifier: DynamicAdUnitId)
            _dynamicRewarded!.delegate = self
            _dynamicRewarded!.setExtraParameterForKey("disable_auto_retries", value: "true")
            _dynamicRewarded!.setExtraParameterForKey("jC7Fp", value: bidFloorParam)
            _dynamicRewarded!.load()
            
            ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: _dynamicRewarded!, insight: insight)
        }
    }
    
    private func LoadDefault() {
        _defaultRewarded = MARewardedAd.shared(withAdUnitIdentifier: DefaultAdUnitId)
        _defaultRewarded!.delegate = self
        _defaultRewarded!.load()
        
        ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: _defaultRewarded!)
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        if adUnitIdentifier == DynamicAdUnitId {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withRewarded: _dynamicRewarded!, error: error)
            
            Log("Load failed Dynamic \(adUnitIdentifier): \(error)")
            
            _dynamicRewarded = nil
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
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withRewarded: _defaultRewarded!, error: error)
            
            Log("Load failed Default \(adUnitIdentifier): \(error)")
            
            _defaultRewarded = nil
            if _loadSwitch.isOn {
                LoadDefault()
            }
        }
    }
    
    func didLoad(_ ad: MAAd) {
        if ad.adUnitIdentifier == DynamicAdUnitId {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withRewarded: _dynamicRewarded!, ad: ad)
            
            Log("Load Dynamic \(ad) at: \(ad.revenue)")
            
            _consecutiveDynamicFails = 0
            _dynamicAdRevenue = ad.revenue
        } else {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withRewarded: _defaultRewarded!, ad: ad)
            
            Log("Load Default \(ad) at: \(ad.revenue)")
            
            _defaultAdRevenue = ad.revenue
        }

        UpdateShowButton()
    }
    
    func didPayRevenue(for ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
        
        Log("didPayRevenue \(ad.adUnitIdentifier) revenue: \(ad.revenue)")
    }
    
    func didClick(_ ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationClick(ad)
        
        Log("didClick \(ad)")
    }
    
    init(viewController: ViewController, loadSwitch: UISwitch, showButton: UIButton, status: UILabel) {
        _viewController = viewController
        _loadSwitch = loadSwitch
        _showButton = showButton
        _status = status
        
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
        if _dynamicRewarded!.isReady {
            _dynamicRewarded!.show()
            isShown = true
        }
        _dynamicAdRevenue = -1
        _dynamicRewarded = nil
        return isShown
    }
    
    private func TryShowDefault() -> Bool {
        var isShown = false
        if _defaultRewarded!.isReady {
            _defaultRewarded!.show()
            isShown = true
        }
        _defaultAdRevenue = -1
        _defaultRewarded = nil
        return isShown
    }

    func didDisplay(_ ad: MAAd) {
        Log("didDisplay \(ad)")
    }

    func didHide(_ ad: MAAd) {
        Log("didHide \(ad)")
        
        // start new load cycle
        if (_loadSwitch.isOn) {
            StartLoading();
        }
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        Log("didFail \(ad)")
    }

    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        Log("didRewardUser \(ad) \(reward)")
    }
    
    func UpdateShowButton() {
        _showButton.isEnabled = _dynamicAdRevenue >= 0 || _defaultAdRevenue >= 0
    }
    
    private func Log(_ log: String) {
        _status.text = log
        print("NeftaPluginMAX Rewarded: \(log)")
    }
}
