//
//  InterstitialDefault.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 7. 5. 26.
//

class InterstitialDefault : NSObject, MAAdDelegate, MAAdRevenueDelegate, Interstitial {
    
    var _ui: InterstitialUi!
    var _interstitial: MAInterstitialAd!
    var _consecutiveAdFails: Int = 0
    
    func Init(ui: InterstitialUi) {
        _ui = ui
        
        _interstitial = MAInterstitialAd(adUnitIdentifier: InterstitialUi.AdUnitA)
        _interstitial.delegate = self
        _interstitial.revenueDelegate = self
    }
    
    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        ALNeftaMediationAdapter.onExternalMediationRequestFail(withInterstitial: _interstitial, error: error)
        
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
        ALNeftaMediationAdapter.onExternalMediationRequestLoad(withInterstitial: _interstitial, ad: ad)
        
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

    func didHide(_ ad: MAAd) {
        Log("didHide \(ad)")
        
        if _ui.IsAutoLoad {
            Load()
        }
    }
    
    public func Load() {
        ALNeftaMediationAdapter.onExternalMediationRequest(withInterstitial: _interstitial)
        _interstitial.load()
    }
    
    public func Show() {
        if _interstitial.isReady {
            _interstitial.show()
        } else if _ui.IsAutoLoad {
            Load()
        }
        
        _ui.SetAvailable(available: false)
    }
    
    private func Log(_ log: String) {
        _ui.Log(log)
    }
}
