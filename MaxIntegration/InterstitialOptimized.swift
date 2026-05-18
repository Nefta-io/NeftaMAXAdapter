//
//  InterstitialOptimized.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class InterstitialOptimized : Interstitial {

    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
        case Shown
    }
    
    public class Track : NSObject, MAAdDelegate, MAAdRevenueDelegate {
        private let _controller: InterstitialOptimized
        
        public let _adUnitId: String
        public var _interstitial: MAInterstitialAd!
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        
        public init(controller: InterstitialOptimized, adUnitId: String) {
            _controller = controller
            _adUnitId = adUnitId
            
            super.init()
            
            Reset()
        }
        
        public func Reset() {
            if let oldInterstitial = _interstitial {
                oldInterstitial.delegate = nil
                oldInterstitial.revenueDelegate = nil
            }
            
            _interstitial = MAInterstitialAd(adUnitIdentifier: _adUnitId)
            _interstitial.delegate = self
            _interstitial.revenueDelegate = self
            
            _state = State.Idle
            _insight = nil
            _revenue = -1
        }
        
        func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withInterstitial: _interstitial, error: error)
            
            _controller.Log("Load failed \(adUnitIdentifier): \(error)")
            
            OnLoadFail()
        }
        
        public func OnLoadFail() {
            retryLoad()
            
            _controller.OnTrackLoad(false)
        }
        
        func didLoad(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withInterstitial: _interstitial, ad: ad)
            
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

        func didHide(_ ad: MAAd) {
            _controller.Log("didHide \(ad)")
            
            _state = .Idle
            _controller.RetryLoadTracks()
        }
    }

    private var _trackA: Track!
    private var _trackB: Track!
    private var _isFirstResponseReceived = false

    var _ui: InterstitialUi!
    
    func Init(ui: InterstitialUi) {
        _ui = ui
        
        _trackA = Track(controller: self, adUnitId: InterstitialUi.AdUnitA)
        _trackB = Track(controller: self, adUnitId: InterstitialUi.AdUnitB)
        ALNeftaMediationAdapter.AddNewSessionCallback(callback: OnNewSession)
    }
    
    public func Load() {
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
        
        NeftaPlugin._instance!.GetInsights(Insights.Interstitial, previousInsight: track._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._interstitial {
                track._insight = insight
                var bidFloor = ""
                if insight._floorPrice >= 0 {
                    bidFloor = String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), insight._floorPrice)
                }

                track._interstitial.setExtraParameterForKey("disable_auto_retries", value: "true")
                track._interstitial.setExtraParameterForKey("jC7Fp", value: bidFloor)
                
                ALNeftaMediationAdapter.onExternalMediationRequest(withInterstitial: track._interstitial, insight: insight)
                
                self.Log("Loading \(track._adUnitId) as Optimized with floor: \(bidFloor)")
                track._interstitial.load()
            } else {
                track.OnLoadFail()
            }
        })
    }
    
    private func LoadDefault(track: Track) {
        track._state = .Loading
        
        Log("Loading \(track._adUnitId) as Default")
        
        track._interstitial.setExtraParameterForKey("disable_auto_retries", value: "false")
        track._interstitial.setExtraParameterForKey("jC7Fp", value: "")
        
        ALNeftaMediationAdapter.onExternalMediationRequest(withInterstitial: track._interstitial)
        
        track._interstitial.load()
    }
    
    private func OnNewSession() {
        Log("Inter on new session")
        
        _trackA.Reset()
        _trackB.Reset()
        
        UpdateAvailability()
        _isFirstResponseReceived = false
        RetryLoadTracks()
    }
    
    public func Show() {
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
        
        UpdateAvailability()
    }
    
    private func TryShow(track: Track) -> Bool {
        track._revenue = -1
        if track._interstitial.isReady {
            track._state = .Shown
            track._interstitial.show()
            return true
        }
        track._state = .Idle
        RetryLoadTracks()
        return false
    }
    
    private func RetryLoadTracks() {
        if _ui.IsAutoLoad {
            Load()
        }
    }
    
    private func OnTrackLoad(_ success: Bool) {
        if success {
            UpdateAvailability()
        }
        
        _isFirstResponseReceived = true
        RetryLoadTracks()
    }
    
    private func UpdateAvailability() {
        _ui.SetAvailable(available: _trackA._state == .Ready || _trackB._state == .Ready)
    }
    
    private func Log(_ log: String) {
        _ui.Log(log)
    }
}
