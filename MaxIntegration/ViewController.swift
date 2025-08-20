//
//  ViewController.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import UIKit

import NeftaSDK
import AppLovinSDK
import AdSupport
import AppTrackingTransparency

@objc(ViewController)
public class ViewController: UIViewController {

    var _plugin: NeftaPlugin!
    
    var _banner: Banner!
    var _interstitial: Interstitial!
    var _interstitialObjC: InterstitialObjC!
    var _rewardedVideo: Rewarded!
    
    @IBOutlet weak var _bannerPlaceholder: UIView!
    @IBOutlet weak var _showBanner: UIButton!
    @IBOutlet weak var _hideBanner: UIButton!
    @IBOutlet weak var _loadInterstitial: UIButton!
    @IBOutlet weak var _showInterstitial: UIButton!
    @IBOutlet weak var _loadRewarded: UISwitch!
    @IBOutlet weak var _showRewarded: UIButton!
    @IBOutlet weak var _title: UILabel!
    @IBOutlet weak var _bannerStatus: UILabel!
    @IBOutlet weak var _interstitialStatus: UILabel!
    @IBOutlet weak var _rewardedStatus: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        NeftaPlugin.EnableLogging(enable: true)
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.count > 1 {
            NeftaPlugin.SetOverride(url: arguments[1])
        }
        
        _plugin = NeftaPlugin.Init(appId: "5661184053215232")

        _title.text = "Nefta Adapter for MAX"
        _banner = Banner(viewController: self, showButton: _showBanner, hideButton: _hideBanner)
        _interstitial = Interstitial(viewController: self, loadButton: _loadInterstitial, showButton: _showInterstitial)
        //_interstitialObjC = InterstitialObjC(_bannerPlaceholder, load: _loadInterstitial, show: _showInterstitial)
        _rewardedVideo = Rewarded(viewController: self, loadSwitch: _loadRewarded, showButton: _showRewarded, status: _rewardedStatus)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.checkTrackingAndInitializeMax()
        }
    }
    
    private func checkTrackingAndInitializeMax() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    self.initializeAdSdk(isTrackingEnabled: status == .authorized)
                }
            }
        } else {
            initializeAdSdk(isTrackingEnabled: ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
        }
    }
    
    private func initializeAdSdk(isTrackingEnabled: Bool) {
        ALPrivacySettings.setHasUserConsent(isTrackingEnabled)
        
        let max = ALSdk.shared()
        let adUnits = [
          // interstitials
          "6d318f954e2630a8", "37146915dc4c7740", "e5dc3548d4a0913f",
          // rewarded
          "918acf84edf9c034", "37163b1a07c4aaa0", "e0b0d20088d60ec5"
        ]
        max.settings.setExtraParameterForKey("disable_b2b_ad_unit_ids", value: adUnits.joined(separator: ","))
        max.settings.setExtraParameterForKey("google_max_ad_content_rating", value: "MA")
        
        max.settings.isVerboseLoggingEnabled = true
        let initConfig = ALSdkInitializationConfiguration(sdkKey: "IAhBswbDpMg9GhQ8NEKffzNrXQP1H4ABNFvUA7ePIz2xmarVFcy_VB8UfGnC9IPMOgpQ3p8G5hBMebJiTHv3P9") { builder in
            builder.mediationProvider = ALMediationProviderMAX
        }
        max.initialize(with: initConfig) { sdkConfig in

        }
    }
    
    @objc func OnFullScreenAdDisplay(displayed: Bool) {
        _banner.SetAutoRefresh(refresh: !displayed)
    }
    
    @objc func Log(type: Int, log: String) {
        var tag: String = ""
        if type == 1 {
            _bannerStatus.text = log
            tag = "Banner"
        } else if type == 2 {
            _interstitialStatus.text = log
            tag = "Interstitial"
        } else if type == 3 {
            _rewardedStatus.text = log
            tag = "Rewarded"
        }
        print("NeftaPluginINT \(tag): \(log)")
    }
}

