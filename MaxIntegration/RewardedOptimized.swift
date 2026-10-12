//
//  RewardedOptimized.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//


import Foundation
import AppLovinSDK

class RewardedOptimized : Rewarded {
    
    public enum State {
        case Idle
        case Loading
        case Ready
        case Shown
        case Delay
    }
    
    public class Track : NSObject, MARewardedAdDelegate, MAAdRevenueDelegate {
        private let _controller: RewardedOptimized
        
        public let _adUnitId: String
        public let _isOptimized: Bool
        public let _rewarded: MARewardedAd!
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        
        public init(controller: RewardedOptimized, adUnitId: String, isOptimized: Bool) {
            _controller = controller
            _adUnitId = adUnitId
            _isOptimized = isOptimized
            
            _rewarded = MARewardedAd.shared(withAdUnitIdentifier: _adUnitId)
            
            super.init()
            
            if _isOptimized {
                _rewarded.setExtraParameterForKey("disable_auto_retries", value: "true")
            }
            _rewarded.delegate = self
            _rewarded.revenueDelegate = self
        }
        
        func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withRewarded: _rewarded, error: error)
            
            _controller.Log("Load failed \(adUnitIdentifier): \(error)")
            
            _controller.OnTrackLoad(track: self, success: false)
        }
        
        func didLoad(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withRewarded: _rewarded, ad: ad)
            
            _controller.Log("Loaded \(ad) at: \(ad.revenue)")
            
            _insight = nil
            _revenue = ad.revenue
            _state = .Ready
            
            _controller.OnTrackLoad(track: self, success: true)
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
            _controller.ContinueLoading()
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
            _controller.ContinueLoading()
        }
    }
    
    private var _tracks: [Track]! = nil
    private var _isFirstRequest = true
    private var _isFirstOptimizedResponseReceived = false
    private var _isGlobalCooldown: Int = 0
    
    private var _ui: RewardedUi!
    
    func Init(ui: RewardedUi) {
        _ui = ui
        
        _tracks = [
            Track(controller: self, adUnitId: RewardedUi.AdUnitDefault, isOptimized: false),
            Track(controller: self, adUnitId: RewardedUi.AdUnitOptimizedA, isOptimized: true),
            Track(controller: self, adUnitId: RewardedUi.AdUnitOptimizedB, isOptimized: true)
        ]
    }
    
    public func Load() {
        if _isFirstRequest {
            Load(track: _tracks[1])
            
            let stopWaitingForFirstResponseAfter = NeftaPlugin._instance?._state._firstResponseTimeoutRewardedInMs ?? 0
            if stopWaitingForFirstResponseAfter > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(stopWaitingForFirstResponseAfter) * 0.001) {
                    if !self._isFirstOptimizedResponseReceived {
                        self._isFirstOptimizedResponseReceived = true
                        if self._tracks.count > 2 && self._tracks[2]._state == .Idle {
                            self.Load(track: self._tracks[2])
                        }
                        if NeftaPlugin._instance!._state._backfillTrackDelayInMs < 0 && self._tracks[0]._state == .Idle {
                            self.Load(track: self._tracks[0])
                        }
                    }
                }
            }
            
            let backFillTrackDelayInMs = NeftaPlugin._instance!._state._backfillTrackDelayInMs
            if (backFillTrackDelayInMs == 0) {
                Load(track: _tracks[0])
            } else if (backFillTrackDelayInMs > 0) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(backFillTrackDelayInMs) * 0.001) {
                    self.Load(track: self._tracks[0])
                }
            }
            
            _isFirstRequest = false
        } else {
            ContinueLoading()
        }
    }
    
    private func Load(track: Track) {
        track._state = .Loading

        if track._isOptimized {
            ALNeftaMediationAdapter.getInsights(Insights.Rewarded, previousInsight: track._insight, callback: { insights in
                self.Log("Load with insights: \(insights)")
                if let insight = insights._rewarded {
                    track._insight = insight
                    var bidFloor = ""
                    if insight._floorPrice >= 0 {
                        bidFloor = String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), insight._floorPrice)
                    }
       
                    track._rewarded.setExtraParameterForKey("jC7Fp", value: bidFloor)
                    
                    ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: track._rewarded, insight: insight)
                    
                    self.Log("Loading \(track._adUnitId) as Optimized with floor: \(bidFloor)")
                    track._rewarded.load()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(NeftaPlugin.GetRetryDelayInSeconds(insight: track._insight, adUnitId: track._adUnitId))) {
                        track._state = State.Idle
                        self.ContinueLoading()
                    }
                }
            })
        } else {
            ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: track._rewarded)
            
            Log("Loading \(track._adUnitId) as Default")
            track._rewarded.load()
        }
    }

    public func ContinueOptimized() {
        _isFirstOptimizedResponseReceived = true
        if _tracks[0]._state == .Idle {
            Load(track: _tracks[0])
        }
        
        _isGlobalCooldown += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(NeftaPlugin._instance!._state._globalTrackCooldownInMs * 1000)) {
            self._isGlobalCooldown -= 1
            if self._isGlobalCooldown <= 0 {
                self._isGlobalCooldown = 0
                self.ContinueLoading()
            }
        }
    }
    
    public func ContinueLoading() {
        if !_ui.IsAutoLoad {
            return
        }
        
        if _tracks[0]._state == .Idle {
            Load(track: _tracks[0])
        }
        if _isGlobalCooldown > 0 {
            return
        }
        for i in 1..<_tracks.count {
            if _tracks[i]._state == .Loading {
                return
            }
        }
        for i in 1..<_tracks.count {
            if _tracks[i]._state == .Idle {
                Load(track: _tracks[i])
                return
            }
        }
    }
    
    public func Show() {
        var isShown = false
        let readyTrack = GetReadyTrack()
        if let trackToShow = readyTrack {
            isShown = TryShow(track: trackToShow)
        }
        if !isShown {
            ContinueLoading()
        }
        let availableTrack = GetReadyTrack()
        _ui.SetAvailable(available: availableTrack != nil)
    }
    
    private func TryShow(track: Track) -> Bool {
        track._revenue = -1
        if track._rewarded.isReady {
            track._state = .Shown
            track._rewarded.show()
            return true
        }
        track._state = .Idle
        Load()
        return false
    }
    
    private func OnTrackLoad(track: Track, success: Bool) {
        if success {
            _ui.SetAvailable(available: true)
        } else {
            track._state = .Delay
            let delay = Double(NeftaPlugin.GetRetryDelayInSeconds(insight: track._insight, adUnitId: track._adUnitId))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                track._state = State.Idle
                self.ContinueLoading()
            }
        }
        
        if track._isOptimized {
            ContinueOptimized()
        }
    }
    
    private func GetReadyTrack() -> Track? {
        var bestTrack: Track?
        for track in _tracks {
            if track._state == .Ready && (bestTrack == nil || track._revenue > bestTrack!._revenue) {
                bestTrack = track
            }
        }
        return bestTrack
    }
        
    private func Log(_ log: String) {
        _ui.Log(log)
    }
}
