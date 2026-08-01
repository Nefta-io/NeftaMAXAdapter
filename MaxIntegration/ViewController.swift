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
        InterstitialUi.AdUnitA, InterstitialUi.AdUnitB,
        RewardedUi.AdUnitA, RewardedUi.AdUnitB
    ]
    
    @IBOutlet weak var _title: UILabel!
    @IBOutlet weak var _consentCheckBox: UISwitch!
    @IBOutlet weak var _isSimulatorCheckBox: UISwitch!
    @IBOutlet weak var _simulatorLabel: UILabel!
    @IBOutlet weak var _groupView: UIView!
    @IBOutlet weak var _controlButton: UIButton!
    @IBOutlet weak var _optimizedButton: UIButton!
    
    @IBOutlet weak var _interstitialUi: InterstitialUi!
    @IBOutlet weak var _rewardedUi: RewardedUi!
    @IBOutlet weak var _interstitialSim: InterstitialSim!
    @IBOutlet weak var _rewardedSim: RewardedSim!
    
    private var _isMaxReady: Bool = false
    private var _isNeftaReady: Bool = false
    
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
    
    private func OnAdLogicReady() {
        if _isMaxReady && _isNeftaReady {
            _interstitialUi.OnAdLogicReady()
            _rewardedUi.OnAdLogicReady()
            
            _interstitialSim.OnAdLogicReady()
            _rewardedSim.OnAdLogicReady()
        }
    }
    
    private func InitializeNefta() {
        NeftaPlugin.EnableLogging(enable: true)
        ALNeftaMediationAdapter.Init(appId: "5661184053215232", onReady: { initConfig in
            ViewController._log.notice("[NeftaPluginMAX] Initialized, nuid: \(initConfig._nuid)")
            self._isNeftaReady = true
            self.OnAdLogicReady()
        })
    }
    
    private func InitializeMAX(isOptimized: Bool) {
        let max = ALSdk.shared()
        max.settings.isVerboseLoggingEnabled = true
        
        NeftaPlugin.SetInterstitialLogic(isOptimized: isOptimized)
        NeftaPlugin.SetRewardedLogic(isOptimized: isOptimized)
        if isOptimized {
            max.settings.setExtraParameterForKey("disable_b2b_ad_unit_ids", value: self._dynamicAdUnits.joined(separator: ","))
        }
    
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
            self._isMaxReady = true
            self.OnAdLogicReady()
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
        
        _controlButton.addTarget(self, action: #selector(OnControlClick), for: .touchUpInside)
        _optimizedButton.addTarget(self, action: #selector(OnOptimizedClick), for: .touchUpInside)
    }
    
    @objc func OnConsentCheck() {
        NeftaPlugin.SetHasUserConsent(hasUserConsent: false)
        _consentCheckBox.isEnabled = false
    }
    
    @objc func OnControlClick() {
        Initialize(isOptimized: false)
    }
    
    @objc func OnOptimizedClick() {
        Initialize(isOptimized: true)
    }
    
    private func Initialize(isOptimized: Bool) {
        InitializeNefta()
        _groupView.isHidden = true
        
        if _isSimulatorCheckBox.isOn {
            _isMaxReady = true
            
            _interstitialSim.SetOptimized(isOptimized: isOptimized)
            _rewardedSim.SetOptimized(isOptimized: isOptimized)
        } else {
            InitializeMAX(isOptimized: isOptimized)
        }
        _isSimulatorCheckBox.isHidden = true
        _simulatorLabel.isHidden = true
    }
}

