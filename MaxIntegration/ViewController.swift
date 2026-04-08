//
//  ViewController.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import UIKit
import NeftaSDK
import AppLovinSDK
import OSLog
import AppTrackingTransparency
import AdSupport

@objc(ViewController)
public class ViewController: UIViewController {

    public static var _log = Logger(subsystem: "com.nefta.max", category: "general")
    
    private var _isSimulator = false
    
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
        
        InitializeUI()
        DebugServer.Init(viewController: self)
        
        NeftaPlugin.EnableLogging(enable: true)
        ALNeftaMediationAdapter.Init(appId: "5661184053215232", onReady: { initConfig in
            ViewController._log.notice("[NeftaPluginMAX] Should skip Nefta optimization: \(initConfig._skipOptimization) for: \(initConfig._nuid)")
            
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    DispatchQueue.main.async {
                        self.initializeMAX(isTrackingEnabled: status == .authorized)
                    }
                }
            } else {
                self.initializeMAX(isTrackingEnabled: ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
            }
        })
    }
    
    private func initializeMAX(isTrackingEnabled: Bool) {
        ALPrivacySettings.setHasUserConsent(isTrackingEnabled)

        let max = ALSdk.shared()
        max.settings.isVerboseLoggingEnabled = true
        
        max.settings.setExtraParameterForKey("disable_b2b_ad_unit_ids", value: self._dynamicAdUnits.joined(separator: ","))
    
        var maxKey = ""
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) {
            if let mK = dict["MAX_KEY"] as? String {
                maxKey = mK
            }
        }
        let initConfig = ALSdkInitializationConfiguration(sdkKey: maxKey) { builder in
            builder.mediationProvider = ALMediationProviderMAX
            builder.testDeviceAdvertisingIdentifiers = [
                "6AE31431-72EA-44BD-9732-8159D827E21C",
                "B656BE16-9A12-4A0E-B160-DBEDFEC7F4C6"
            ]
        }
        max.initialize(with: initConfig) { sdkConfig in

        }
    }
    
    private func InitializeUI() {
        let title = view.viewWithTag(10) as? UILabel
        title!.text = "Nefta Adapter for\n MAX \(ALSdk.version())"
        let onClickHandler = UITapGestureRecognizer(target: self, action: #selector(onTitleClick))
        title!.isUserInteractionEnabled = true
        title!.addGestureRecognizer(onClickHandler)
        
        var isSimulator: Bool = false
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) {
            isSimulator = dict["IS_SIMULATOR"] as? Bool ?? false
        }
        ToggleUI(isSimulator: isSimulator)
    }
    
    @objc func onTitleClick() {
        ToggleUI(isSimulator: !_isSimulator)
    }
    
    private func ToggleUI(isSimulator: Bool) {
        _isSimulator = isSimulator
        
        (view.viewWithTag(11) as! InterstitialSim).isHidden = !isSimulator
        (view.viewWithTag(12) as! RewardedSim).isHidden = !isSimulator
        
        (view.viewWithTag(13) as! Interstitial).isHidden = isSimulator
        (view.viewWithTag(14) as! Rewarded).isHidden = isSimulator
    }
}

