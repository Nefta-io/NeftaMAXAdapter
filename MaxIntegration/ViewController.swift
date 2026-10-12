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
    
    private var _dynamicAdUnits = [
        InterstitialUi.AdUnitOptimizedA, InterstitialUi.AdUnitOptimizedB,
        RewardedUi.AdUnitOptimizedA, RewardedUi.AdUnitOptimizedB
    ]
    
    private enum TestGroup {
        case Control
        case Optimized
        case NeftaDecides
    }
    
    @IBOutlet weak var _title: UILabel!
    @IBOutlet weak var _consentCheckBox: UISwitch!
    @IBOutlet weak var _isSimulatorCheckBox: UISwitch!
    @IBOutlet weak var _simulatorLabel: UILabel!
    @IBOutlet weak var _groupView: UIView!
    @IBOutlet weak var _unknownButton: UIButton!
    @IBOutlet weak var _optimizedButton: UIButton!
    @IBOutlet weak var _notOptimizedButton: UIButton!
    
    @IBOutlet weak var _interstitialUi: InterstitialUi!
    @IBOutlet weak var _rewardedUi: RewardedUi!
    @IBOutlet weak var _interstitialSim: InterstitialSim!
    @IBOutlet weak var _rewardedSim: RewardedSim!

    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        InitializeUI()
        DebugServer.Init(viewController: self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    DispatchQueue.main.async {
                        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                        print("NeftaPlugin IDFA: \(idfa)")
                    }
                }
            } else {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                print("NeftaPlugin IDFA: \(idfa)")
            }
        }
    }
    
    private func InitializeNefta(optimizationType: OptimizationType) {
        NeftaPlugin.EnableLogging(enable: true)
        NeftaPlugin.SetHasUserConsent(hasUserConsent: _consentCheckBox.isOn)
        ALNeftaMediationAdapter.Init(appId: "5661184053215232", optimizationType: optimizationType, onReady: { config in
            ViewController._log.notice("[NeftaPluginMAX] Initialized, nuid: \(config._nuid) should optimize: \(config._isSessionOptimized)")
    
            self.InitializeMAX(isOptimized: config._isSessionOptimized)
        })
    }
    
    private func InitializeMAX(isOptimized: Bool) {
        ViewController._log.notice("[NeftaPluginMAX] Initializing MAX")
        if self._isSimulatorCheckBox.isOn {
            self._interstitialSim.SetOptimized(isOptimized: isOptimized)
            self._rewardedSim.SetOptimized(isOptimized: isOptimized)
            return
        }
        
        ALPrivacySettings.setHasUserConsent(_consentCheckBox.isOn)
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
        
        if isOptimized {
            _interstitialUi.Init(logic: InterstitialOptimized())
            _rewardedUi.Init(logic: RewardedOptimized())
        } else {
            _interstitialUi.Init(logic: InterstitialDefault())
            _rewardedUi.Init(logic: RewardedDefault())
        }
    }
    
    private func InitializeUI() {
        _title!.text = "Nefta Adapter for\n MAX \(ALSdk.version())"
        
        _consentCheckBox.addTarget(self, action: #selector(OnConsentCheck), for: .touchUpInside)

        
        _unknownButton.addTarget(self, action: #selector(OnUnknownClick), for: .touchUpInside)
        _optimizedButton.addTarget(self, action: #selector(OnOptimizedClick), for: .touchUpInside)
        _notOptimizedButton.addTarget(self, action: #selector(OnNotOptimizedClick), for: .touchUpInside)
    }
    
    @objc func OnUnknownClick() {
        Initialize(optimizationType: .unknown)
    }
    
    @objc func OnOptimizedClick() {
        Initialize(optimizationType: .optimized)
    }
    
    @objc func OnNotOptimizedClick() {
        Initialize(optimizationType: .notOptimized)
    }
    
    @objc func OnConsentCheck() {
        NeftaPlugin.SetHasUserConsent(hasUserConsent: _consentCheckBox.isOn)
    }
    
    private func Initialize(optimizationType: OptimizationType) {
        _groupView.isHidden = true
        _isSimulatorCheckBox.isHidden = true
        _simulatorLabel.isHidden = true
        
        InitializeNefta(optimizationType: optimizationType)
    }
}

