//
//  RewardedDefault.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 7. 5. 26.
//

class RewardedDefault : NSObject, MARewardedAdDelegate, MAAdRevenueDelegate, Rewarded {
    
    var _ui: RewardedUi!
    var _rewarded: MARewardedAd!
    var _consecutiveAdFails: Int = 0
    
    func Init(ui: RewardedUi) {
        _ui = ui
        
        _rewarded = MARewardedAd.shared(withAdUnitIdentifier: RewardedUi.AdUnitA)
        _rewarded.delegate = self
        _rewarded.revenueDelegate = self
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        ALNeftaMediationAdapter.onExternalMediationRequestFail(withRewarded: _rewarded, error: error)
        
        Log("Load failed \(adUnitIdentifier): \(error)")
        
        _consecutiveAdFails += 1
        let delayInSeconds = [0, 2, 4, 8, 16, 32, 64][min(_consecutiveAdFails, 6)]
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayInSeconds)) {
            if self._ui.IsAutoLoad {
                self.Load()
            }
        }
    }
    
    func didLoad(_ ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationRequestLoad(withRewarded: _rewarded, ad: ad)
        
        Log("Loaded \(ad) at: \(ad.revenue)")
        
        _consecutiveAdFails = 0
        
        _ui.SetAvailable(available: true)
    }
    
    func didPayRevenue(for ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationImpression(ad)
        
        Log("didPayRevenueForAd \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
    }
    
    func didClick(_ ad: MAAd) {
        ALNeftaMediationAdapter.onExternalMediationClick(ad)
        
        Log("didClick \(ad)")
    }
    
    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        Log("didFail \(ad)")
        
        if _ui.IsAutoLoad {
            Load()
        }
    }
    
    func didDisplay(_ ad: MAAd) {
        Log("didDisplay \(ad)")
    }
    
    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        Log("didRewardUser \(ad) \(reward)")
    }

    func didHide(_ ad: MAAd) {
        Log("didHide \(ad)")
        
        if _ui.IsAutoLoad {
            Load()
        }
    }
    
    public func Load() {
        ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: _rewarded)
        _rewarded.load()
    }
    
    public func Show() {
        if _rewarded.isReady {
            _rewarded.show()
        } else if _ui.IsAutoLoad {
            Load()
        }
        
        _ui.SetAvailable(available: false)
    }
    
    private func Log(_ log: String) {
        _ui.Log(log)
    }
}
