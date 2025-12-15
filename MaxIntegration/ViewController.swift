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
        "e5dc3548d4a0913f", // track A
        "6d318f954e2630a8", // track B
        // rewarded
        "e0b0d20088d60ec5", // track A
        "918acf84edf9c034"  // track B
    ]
    
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
            
            print("[NeftaPluginMAX] Should bypass Nefta optimization? \(initConfig._skipOptimization)")
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.checkTrackingAndInitializeMax()
        }
    }
    
    private func checkTrackingAndInitializeMax() {
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) {
            if let maxKey = dict["MAX_KEY"] as? String {
                if #available(iOS 14, *) {
                    ATTrackingManager.requestTrackingAuthorization { status in
                        DispatchQueue.main.async {
                            self.initializeAdSdk(maxKey: maxKey, isTrackingEnabled: status == .authorized)
                        }
                    }
                } else {
                    initializeAdSdk(maxKey: maxKey, isTrackingEnabled: ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
                }
            }
        }
    }
    
    private func initializeAdSdk(maxKey: String, isTrackingEnabled: Bool) {
        ALPrivacySettings.setHasUserConsent(isTrackingEnabled)
        
        let max = ALSdk.shared()
        max.settings.setExtraParameterForKey("disable_b2b_ad_unit_ids", value: _dynamicAdUnits.joined(separator: ","))
        max.settings.setExtraParameterForKey("google_max_ad_content_rating", value: "MA")
        
        max.settings.isVerboseLoggingEnabled = true
        
        let initConfig = ALSdkInitializationConfiguration(sdkKey: maxKey) { builder in
            builder.mediationProvider = ALMediationProviderMAX
        }
        max.initialize(with: initConfig) { sdkConfig in

        }
    }
}

