//
//  Rewarded.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Rewarded : UIView {
    private let AdUnitA = "e0b0d20088d60ec5"
    private let AdUnitB = "918acf84edf9c034"
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
        case Shown
    }
    
    public class Track : NSObject, MARewardedAdDelegate, MAAdRevenueDelegate {
        private let _controller: Rewarded
        
        public let _adUnitId: String
        public var _rewarded: MARewardedAd!
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        
        public init(controller: Rewarded, adUnitId: String) {
            _controller = controller
            _adUnitId = adUnitId
            
            super.init()
            
            Reset()
        }
        
        public func Reset() {
            if let oldRewarded = _rewarded {
                oldRewarded.delegate = nil
                oldRewarded.revenueDelegate = nil
            }
            
            _rewarded = MARewardedAd.shared(withAdUnitIdentifier: _adUnitId)
            _rewarded.delegate = self
            _rewarded.revenueDelegate = self
            
            _state = State.Idle
            _insight = nil
            _revenue = -1
        }
        
        func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withRewarded: _rewarded, error: error)
            
            _controller.Log("Load failed \(adUnitIdentifier): \(error)")
            
            OnLoadFail()
        }
        
        public func OnLoadFail() {
            retryLoad()
            
            _controller.OnTrackLoad(false)
        }
        
        func didLoad(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withRewarded: _rewarded, ad: ad)
            
            _controller.Log("Loaded \(ad) at: \(ad.revenue)")
            
            _insight = nil
            _revenue = ad.revenue
            _state = .Ready
            
            _controller.OnTrackLoad(true)
        }
        
        func retryLoad() {
            DispatchQueue.main.asyncAfter(deadline: .now() + ALNeftaMediationAdapter.GetRetryDelayInSeconds(insight: _insight)) {
                self._state = .Idle
                self._controller.RetryLoadTracks()
            }
        }
        
        func didPayRevenue(for ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationImpression(ad)
            
            _controller.Log("didPayRevenueForAd \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
        }
        
        func didClick(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationClick(ad)
            
            _controller.Log("didClick \(ad)")
        }
        
        func didFail(toDisplay ad: MAAd, withError error: MAError) {
            _controller.Log("didFail \(ad)")
            
            _state = State.Idle
            _controller.RetryLoadTracks()
        }
        
        func didDisplay(_ ad: MAAd) {
            _controller.Log("didDisplay \(ad)")
        }
        
        func didRewardUser(for ad: MAAd, with reward: MAReward) {
            _controller.Log("didRewardUser \(ad) \(reward)")
        }

        func didHide(_ ad: MAAd) {
            _controller.Log("didHide \(ad)")
            
            _state = .Idle
            _controller.RetryLoadTracks()
        }
    }
    
    private var _trackA: Track!
    private var _trackB: Track!
    private var _isFirstResponseReceived = false
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    
    private func LoadTracks() {
        LoadTrack(track: _trackA, otherState: _trackB._state)
        LoadTrack(track: _trackB, otherState: _trackA._state)
    }
    
    private func LoadTrack(track: Track, otherState: State) {
        if track._state == .Idle {
            if otherState == .LoadingWithInsights || otherState == .Shown {
                if (_isFirstResponseReceived) {
                    LoadDefault(track: track)
                }
            } else {
                GetInsightsAndLoad(track: track)
            }
        }
    }
    
    private func GetInsightsAndLoad(track: Track) {
        track._state = .LoadingWithInsights
        
        NeftaPlugin._instance!.GetInsights(Insights.Rewarded, previousInsight: track._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._rewarded {
                track._insight = insight
                let bidFloor = String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), insight._floorPrice)
   
                track._rewarded.setExtraParameterForKey("disable_auto_retries", value: "true")
                track._rewarded.setExtraParameterForKey("jC7Fp", value: bidFloor)
                
                ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: track._rewarded, insight: insight)
                
                self.Log("Loading \(track._adUnitId) as Optimized with floor: \(bidFloor)")
                track._rewarded.load()
            } else {
                track.OnLoadFail()
            }
        })
    }
    
    private func LoadDefault(track: Track) {
        track._state = .Loading
        
        Log("Loading \(track._adUnitId) as Default")
        
        track._rewarded.setExtraParameterForKey("disable_auto_retries", value: "false")
        track._rewarded.setExtraParameterForKey("jC7Fp", value: "")
        
        ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: track._rewarded)
        
        track._rewarded.load()
    }
    
    private func OnNewSession() {
        Log("Rewarded on new session")
        
        _trackA.Reset()
        _trackB.Reset()
        
        UpdateShowButton()
        _isFirstResponseReceived = false
        RetryLoadTracks()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        _trackA = Track(controller: self, adUnitId: AdUnitA)
        _trackB = Track(controller: self, adUnitId: AdUnitB)
        ALNeftaMediationAdapter.AddNewSessionCallback(callback: OnNewSession)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    public override var isHidden: Bool {
        didSet {
            if isHidden {
                if let loadSwitch = _loadSwitch {
                    loadSwitch.setOn(false, animated: false)
                }
            }
        }
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            LoadTracks()
        }
    }
    
    @objc private func OnShowClick() {
        var isShown = false
        if _trackA._state == .Ready {
            if _trackB._state == .Ready && _trackB._revenue > _trackA._revenue {
                isShown = TryShow(track: _trackB)
            }
            if !isShown {
                isShown = TryShow(track: _trackA)
            }
        }
        if !isShown && _trackB._state == .Ready {
            isShown = TryShow(track: _trackB)
        }
        
        UpdateShowButton()
    }
    
    private func TryShow(track: Track) -> Bool {
        track._revenue = -1
        if track._rewarded.isReady {
            track._state = .Shown
            track._rewarded.show()
            return true
        }
        track._state = .Idle
        RetryLoadTracks()
        return false
    }
    
    private func RetryLoadTracks() {
        if _loadSwitch.isOn {
            LoadTracks()
        }
    }
    
    private func OnTrackLoad(_ success: Bool) {
        if success {
            UpdateShowButton()
        }
        
        _isFirstResponseReceived = true
        RetryLoadTracks()
    }
    
    func UpdateShowButton() {
        _showButton.isEnabled = _trackA._state == .Ready || _trackB._state == .Ready
    }
        
    private func Log(_ log: String) {
        _status.text = log
        ViewController._log.notice("NeftaPluginMAX Rewarded: \(log, privacy: .public)")
    }
}
