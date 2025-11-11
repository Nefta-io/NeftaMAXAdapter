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
import OSLog

@objc(ViewController)
public class ViewController: UIViewController {

    public static var _log = Logger(subsystem: "com.nefta.max", category: "general")
    
    var _plugin: NeftaPlugin!
    
    var _interstitial: Interstitial!
    var _interstitialObjC: InterstitialObjC!
    var _rewardedVideo: Rewarded!
    var _dynamicAdUnits = [
        // interstitial
        "e5dc3548d4a0913f",
        // rewarded
        "e0b0d20088d60ec5"
    ]
    
    @IBOutlet weak var _loadInterstitial: UISwitch!
    @IBOutlet weak var _showInterstitial: UIButton!
    @IBOutlet weak var _showRewarded: UIButton!
    @IBOutlet weak var _loadRewarded: UISwitch!
    @IBOutlet weak var _title: UILabel!
    @IBOutlet weak var _interstitialStatus: UILabel!
    @IBOutlet weak var _rewardedStatus: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        DebugServer.Init(viewController: self)
        
        NeftaPlugin.EnableLogging(enable: true)
        NeftaPlugin.SetExtraParameter(key: NeftaPlugin.ExtParam_TestGroup, value: "split-max")
        _plugin = NeftaPlugin.Init(appId: "5661184053215232")
        _plugin.OnReady = { initConfig in
            if let dynamicAdUnits = initConfig.GetMediationProviderAdUnits() {
                self._dynamicAdUnits = dynamicAdUnits
            }
        }

        let titleTap = UITapGestureRecognizer(target: self, action: #selector(toSimulationMode))
        _title.addGestureRecognizer(titleTap)
        
        _interstitial = Interstitial(viewController: self, loadSwitch: _loadInterstitial, showButton: _showInterstitial, status: _interstitialStatus)
        //_interstitialObjC = InterstitialObjC(_bannerPlaceholder, load: _loadInterstitial, show: _showInterstitial, status: _interstitialStatus)
        _rewardedVideo = Rewarded(viewController: self, loadSwitch: _loadRewarded, showButton: _showRewarded, status: _rewardedStatus)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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
        max.settings.setExtraParameterForKey("disable_b2b_ad_unit_ids", value: _dynamicAdUnits.joined(separator: ","))
        max.settings.setExtraParameterForKey("google_max_ad_content_rating", value: "MA")
        
        max.settings.isVerboseLoggingEnabled = true
        let initConfig = ALSdkInitializationConfiguration(sdkKey: "IAhBswbDpMg9GhQ8NEKffzNrXQP1H4ABNFvUA7ePIz2xmarVFcy_VB8UfGnC9IPMOgpQ3p8G5hBMebJiTHv3P9") { builder in
            builder.mediationProvider = ALMediationProviderMAX
        }
        max.initialize(with: initConfig) { sdkConfig in

        }
    }
    
    @objc private func toSimulationMode() {
        
    }
}

