//
//  Rewarded.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Rewarded {
    private let AdUnitA = "e0b0d20088d60ec5"
    private let AdUnitB = "918acf84edf9c034"
    private let TimeoutInSeconds = 5
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
    }
    
    public class AdRequest : NSObject, MARewardedAdDelegate, MAAdRevenueDelegate {
        public let _adUnitId: String
        public var _rewarded: MARewardedAd? = nil
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        public var _consecutiveAdFails: Int = 0
        
        public init(adUnitId: String) {
            _adUnitId = adUnitId
        }
        
        func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withRewarded: _rewarded!, error: error)
            
            Rewarded.Instance.Log("Load failed \(adUnitIdentifier): \(error)")
            
            _rewarded = nil
            OnLoadFail()
        }
        
        public func OnLoadFail() {
            _consecutiveAdFails += 1
            retryLoad()
            
            Rewarded.Instance.OnTrackLoad(false)
        }
        
        func didLoad(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withRewarded: _rewarded!, ad: ad)
            
            Rewarded.Instance.Log("Loaded \(ad) at: \(ad.revenue)")
            
            _insight = nil
            _consecutiveAdFails = 0
            _revenue = ad.revenue
            _state = State.Ready
            
            Rewarded.Instance.OnTrackLoad(true)
        }
        
        func retryLoad() {
            // As per MAX recommendations, retry with exponentially higher delays up to 64s
            // In case you would like to customize fill rate / revenue please contact our customer support
            let delayInSeconds = [0, 2, 4, 8, 16, 32, 64][min(_consecutiveAdFails, 6)]
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayInSeconds)) {
                self._state = State.Idle
                Rewarded.Instance.RetryLoading()
            }
        }
        
        func didPayRevenue(for ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationImpression(ad)
            
            Rewarded.Instance.Log("didPayRevenueForAd \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
        }
        
        func didClick(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationClick(ad)
            
            Rewarded.Instance.Log("didClick \(ad)")
        }
        
        func didFail(toDisplay ad: MAAd, withError error: MAError) {
            Rewarded.Instance.Log("didFail \(ad)")
            
            Rewarded.Instance.RetryLoading()
        }
        
        func didDisplay(_ ad: MAAd) {
            Rewarded.Instance.Log("didDisplay \(ad)")
        }
        
        func didRewardUser(for ad: MAAd, with reward: MAReward) {
            Rewarded.Instance.Log("didRewardUser \(ad) \(reward)")
        }

        func didHide(_ ad: MAAd) {
            Rewarded.Instance.Log("didHide \(ad)")
            
            Rewarded.Instance.RetryLoading()
        }
    }
    
    private var _adRequestA: AdRequest
    private var _adRequestB: AdRequest
    private var _isFirstResponseRecieved = false
    
    private let _loadSwitch: UISwitch
    private let _showButton: UIButton
    private let _status: UILabel
    
    public static var Instance: Rewarded!
    
    private func StartLoading() {
        Load(request: _adRequestA, otherState: _adRequestB._state)
        Load(request: _adRequestB, otherState: _adRequestA._state)
    }
    
    private func Load(request: AdRequest, otherState: State) {
        if request._state == State.Idle {
            if otherState != State.LoadingWithInsights {
                GetInsightsAndLoad(adRequest: request)
            } else if (_isFirstResponseRecieved) {
                LoadDefault(adRequest: request)
            }
        }
    }
    
    private func GetInsightsAndLoad(adRequest: AdRequest) {
        adRequest._state = State.LoadingWithInsights
        
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, previousInsight: adRequest._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._rewarded {
                adRequest._insight = insight
                let bidFloor = String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), insight._floorPrice)
                adRequest._rewarded = MARewardedAd.shared(withAdUnitIdentifier: adRequest._adUnitId)
                adRequest._rewarded!.delegate = adRequest
                adRequest._rewarded!.setExtraParameterForKey("disable_auto_retries", value: "true")
                adRequest._rewarded!.setExtraParameterForKey("jC7Fp", value: bidFloor)
                
                ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: adRequest._rewarded!, insight: insight)
                
                self.Log("Loading \(adRequest._adUnitId) as Optimized with floor: \(bidFloor)")
                adRequest._rewarded!.load()
            } else {
                adRequest.OnLoadFail()
            }
        }, timeout: TimeoutInSeconds)
    }
    
    private func LoadDefault(adRequest: AdRequest) {
        adRequest._state = State.Loading
        
        Log("Loading \(adRequest._adUnitId) as Default")
        
        adRequest._rewarded = MARewardedAd.shared(withAdUnitIdentifier: adRequest._adUnitId)
        adRequest._rewarded!.delegate = adRequest
        
        ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: adRequest._rewarded!)
        
        adRequest._rewarded!.load()
    }
    
    init(loadSwitch: UISwitch, showButton: UIButton, status: UILabel) {
        _loadSwitch = loadSwitch
        _showButton = showButton
        _status = status
        
        _adRequestA = AdRequest(adUnitId: AdUnitA)
        _adRequestB = AdRequest(adUnitId: AdUnitB)
        
        Rewarded.Instance = self
        
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
        if _adRequestA._state == State.Ready {
            if _adRequestB._state == State.Ready && _adRequestB._revenue > _adRequestA._revenue {
                isShown = TryShow(adRequest: _adRequestB)
            }
            if !isShown {
                isShown = TryShow(adRequest: _adRequestA)
            }
        }
        if !isShown && _adRequestB._state == State.Ready {
            isShown = TryShow(adRequest: _adRequestB)
        }
        
        UpdateShowButton()
    }
    
    private func TryShow(adRequest: AdRequest) -> Bool {
        adRequest._state = State.Idle
        adRequest._revenue = -1
        
        if adRequest._rewarded!.isReady {
            adRequest._rewarded!.show()
            return true
        }
        RetryLoading()
        return false
    }
    
    private func RetryLoading() {
        if _loadSwitch.isOn {
            StartLoading()
        }
    }
    
    private func OnTrackLoad(_ success: Bool) {
        if success {
            UpdateShowButton()
        }
        
        _isFirstResponseRecieved = true
        RetryLoading()
    }
    
    func UpdateShowButton() {
        _showButton.isEnabled = _adRequestA._state == State.Ready || _adRequestB._state == State.Ready
    }
        
    private func Log(_ log: String) {
        _status.text = log
        ViewController._log.info("NeftaPluginMAX Rewarded: \(log, privacy: .public)")
    }
}
