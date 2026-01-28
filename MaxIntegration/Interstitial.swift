//
//  Interstitial.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class Interstitial : UIView {
    private let AdUnitA = "e5dc3548d4a0913f"
    private let AdUnitB = "6d318f954e2630a8"
    private let TimeoutInSeconds = 5
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
        case Shown
    }
    
    public class Track : NSObject, MAAdDelegate, MAAdRevenueDelegate {
        private let _controller: Interstitial
        
        public let _adUnitId: String
        public var _interstitial: MAInterstitialAd
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        public var _consecutiveAdFails: Int = 0
        
        public init(controller: Interstitial, adUnitId: String) {
            _controller = controller
            _adUnitId = adUnitId
            
            _interstitial = MAInterstitialAd(adUnitIdentifier: adUnitId)
            
            super.init()
            
            _interstitial.delegate = self
            _interstitial.revenueDelegate = self
        }
        
        func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withInterstitial: _interstitial, error: error)
            
            _controller.Log("Load failed \(adUnitIdentifier): \(error)")
            
            OnLoadFail()
        }
        
        public func OnLoadFail() {
            _consecutiveAdFails += 1
            retryLoad()
            
            _controller.OnTrackLoad(false)
        }
        
        func didLoad(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withInterstitial: _interstitial, ad: ad)
            
            _controller.Log("Loaded \(ad) at: \(ad.revenue)")
            
            _insight = nil
            _consecutiveAdFails = 0
            _revenue = ad.revenue
            _state = State.Ready
            
            _controller.OnTrackLoad(true)
        }
        
        func retryLoad() {
            // As per MAX recommendations, retry with exponentially higher delays up to 64s
            // In case you would like to customize fill rate / revenue please contact our customer support
            let delayInSeconds = [0, 2, 4, 8, 16, 32, 64][min(_consecutiveAdFails, 6)]
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayInSeconds)) {
                self._state = State.Idle
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
            
            _controller.RetryLoadTracks()
        }
        
        func didDisplay(_ ad: MAAd) {
            _controller.Log("didDisplay \(ad)")
        }

        func didHide(_ ad: MAAd) {
            _controller.Log("didHide \(ad)")
            
            _state = State.Idle
            
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
        if track._state == State.Idle {
            if otherState == State.LoadingWithInsights {
                if (_isFirstResponseReceived) {
                    LoadDefault(track: track)
                }
            } else {
                GetInsightsAndLoad(track: track)
            }
        }
    }
    
    private func GetInsightsAndLoad(track: Track) {
        track._state = State.LoadingWithInsights
        
        NeftaPlugin._instance!.GetInsights(Insights.Interstitial, previousInsight: track._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._interstitial {
                track._insight = insight
                let bidFloor = String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), insight._floorPrice)

                track._interstitial.setExtraParameterForKey("disable_auto_retries", value: "true")
                track._interstitial.setExtraParameterForKey("jC7Fp", value: bidFloor)
                
                ALNeftaMediationAdapter.onExternalMediationRequest(withInterstitial: track._interstitial, insight: insight)
                
                self.Log("Loading \(track._adUnitId) as Optimized with floor: \(bidFloor)")
                track._interstitial.load()
            } else {
                track.OnLoadFail()
            }
        }, timeout: TimeoutInSeconds)
    }
    
    private func LoadDefault(track: Track) {
        track._state = State.Loading
        
        Log("Loading \(track._adUnitId) as Default")
        
        track._interstitial.setExtraParameterForKey("disable_auto_retries", value: "false")
        track._interstitial.setExtraParameterForKey("jC7Fp", value: "")
        
        ALNeftaMediationAdapter.onExternalMediationRequest(withInterstitial: track._interstitial)
        
        track._interstitial.load()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        _trackA = Track(controller: self, adUnitId: AdUnitA)
        _trackB = Track(controller: self, adUnitId: AdUnitB)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            LoadTracks()
        }
    }
    
    @objc private func OnShowClick() {
        var isShown = false
        if _trackA._state == State.Ready {
            if _trackB._state == State.Ready && _trackB._revenue > _trackA._revenue {
                isShown = TryShow(track: _trackB)
            }
            if !isShown {
                isShown = TryShow(track: _trackA)
            }
        }
        if !isShown && _trackB._state == State.Ready {
            isShown = TryShow(track: _trackB)
        }
        
        UpdateShowButton()
    }
    
    private func TryShow(track: Track) -> Bool {
        track._revenue = -1
        if track._interstitial.isReady {
            track._state = State.Shown
            track._interstitial.show()
            return true
        }
        track._state = State.Idle
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
    
    private func UpdateShowButton() {
        _showButton.isEnabled = _trackA._state == State.Ready || _trackB._state == State.Ready
    }
    
    private func Log(_ log: String) {
        _status.text = log
        ViewController._log.info("NeftaPluginMAX Interstitial: \(log, privacy: .public)")
    }
}
