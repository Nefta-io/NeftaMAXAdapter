//
//  ViewController.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import UIKit
import NeftaSDK
import Adjust
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
    @IBOutlet weak var _miscButton: UIButton!
    @IBOutlet weak var _groupView: UIView!
    @IBOutlet weak var _unknownButton: UIButton!
    @IBOutlet weak var _optimizedButton: UIButton!
    @IBOutlet weak var _notOptimizedButton: UIButton!
    
    @IBOutlet weak var _interstitialUi: InterstitialUi!
    @IBOutlet weak var _rewardedUi: RewardedUi!
    @IBOutlet weak var _interstitialSim: InterstitialSim!
    @IBOutlet weak var _rewardedSim: RewardedSim!

    private var _miscMenu: UIAlertController?
    
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
        } else {
            _interstitialUi.Init(logic: InterstitialDefault())
        }
    }
    
    private func InitializeUI() {
        _title!.text = "Nefta Adapter for\n MAX \(ALSdk.version())"
        
        _consentCheckBox.addTarget(self, action: #selector(OnConsentCheck), for: .touchUpInside)
        _miscButton.addTarget(self, action: #selector(OnMiscClick), for: .touchUpInside)
        
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
    
    @objc func OnMiscClick() {
        if _miscMenu == nil {
            let m = UIAlertController(title: "Miscellaneous menu", message: nil, preferredStyle: .actionSheet)
            m.addAction(UIAlertAction(title: "MMP: Adjust install", style: .default) { _ in
                let data = self.GetAdjustAttributionData()
                
                NeftaPlugin.OnAttributionChanged(mmp: .Adjust, mmpId: data.adid, network: data.network, campaign: data.campaign, costType: data.costType, cost: data.costAmount?.doubleValue ?? 0.0, costCurrency: data.costCurrency)
            })
            m.addAction(UIAlertAction(title: "MMP: AppsFlyer campaign", style: .default) { _ in
                let conversionInfo = self.GetAppsFlyerData(isOrganic: false)
                
                let network = conversionInfo["media_source"] as? String ?? nil
                let campaign = conversionInfo["campaign"] as? String ?? nil
                let costType = conversionInfo["af_cost_model"] as? String ?? nil
                var cost = 0.0;
                if let costObject = conversionInfo["cost_cents_USD"] {
                    if let number = costObject as? NSNumber {
                        cost = number.doubleValue
                    } else if let string = costObject as? String {
                        cost = Double(string)!
                    }
                }
                
                NeftaPlugin.OnAttributionChanged(mmp: .AppsFlyer, mmpId: "af_id", network: network, campaign: campaign, costType: costType, cost: cost, costCurrency: "USD")
            })
            m.addAction(UIAlertAction(title: "MMP: AppsFlyer organic", style: .default) { _ in
                let conversionInfo = self.GetAppsFlyerData(isOrganic: true)
                
                let network = conversionInfo["media_source"] as? String ?? nil
                let campaign = conversionInfo["campaign"] as? String ?? nil
                let costType = conversionInfo["af_cost_model"] as? String ?? nil
                var cost = 0.0;
                if let costObject = conversionInfo["cost_cents_USD"] {
                    if let number = costObject as? NSNumber {
                        cost = number.doubleValue
                    } else if let string = costObject as? String {
                        cost = Double(string)!
                    }
                }
                
                NeftaPlugin.OnAttributionChanged(mmp: .AppsFlyer, mmpId: "af_id", network: network, campaign: campaign, costType: costType, cost: cost, costCurrency: "USD")
            })
            m.addAction(UIAlertAction(title: "IAP: product 1", style: .default) { _ in
                NeftaPlugin.OnPurchase(productId: "product 1", revenue: 3.3, currency: "USD")
            })
            m.addAction(UIAlertAction(title: "IAP: product 2", style: .default) { _ in
                NeftaPlugin.OnPurchase(productId: "product 2", revenue: 1.2, currency: "EUR")
            })
            m.addAction(UIAlertAction(title: "Exception 1: Res", style: .default) { _ in
                NeftaPlugin.OnExternalMediationResponseAsString("applovin-max", id: "id1", id2: "id2", revenue: 1.2, precision: "exact", status: 1, providerStatus: "provider status", networkStatus: "network status", network: "test", baseString: "{d4f");
                                 
            })
            m.addAction(UIAlertAction(title: "Exception 2: Imp", style: .default) { _ in
                NeftaPlugin.OnExternalMediationImpressionAsString(false, provider: "applovin-max", data: "{\"som3eField\":df", id: "id1", id2: "id2");
                                 
            })
            m.addAction(UIAlertAction(title: "Close", style: .cancel))
            _miscMenu = m
        }
        
        if let popover = _miscMenu!.popoverPresentationController {
            popover.sourceView = _miscButton
            popover.sourceRect = _miscButton.bounds
        }
        present(_miscMenu!, animated: true)
    }
    
    private func GetAdjustAttributionData() -> ADJAttribution {
        let data = ADJAttribution()
        data.adid = "3fa82910b82f013b94cd001a5d28b17a"
        data.network = "test_network"
        data.campaign = "test_campaign"
        data.costType = "cpi"
        data.costAmount = 2.21
        data.costCurrency = "USD"
        return data
    }
    
    private func GetAppsFlyerData(isOrganic: Bool) -> [String: Any] {
        var json: String? = nil
        if isOrganic {
            json = "{\"af_status\":\"Organic\",\"af_message\":\"organicinstall\",\"install_time\":\"2021-08-2306:59:51.194\"}"
        } else {
            json = "{\"adgroup\":null,\"campaign\":\"campaign_name\",\"media_source\":\"applovin_int\",\"retargeting_conversion_type\":\"none\",\"adset_id\":null,\"campaign_id\":null,\"install_time\":\"2018-12-3023:49:54.186\",\"adgroup_id\":null,\"orig_cost\":\"0.0\",\"click_time\":\"2018-12-2414:29:33.738\",\"agency\":null,\"cost_cents_USD\":\"0\",\"af_ad_type\":\"INTER\",\"af_c_id\":\"b8******************************\",\"adset\":null,\"advertising_id\":\"50********************************\",\"af_sub1\":null,\"clickid\":\"10****************\",\"af_click_lookback\":\"7d\",\"af_siteid\":\"123_site_id\",\"af_ad\":\"ad_name\",\"http_referrer\":null,\"af_channel\":\"video\",\"af_adset\":\"_DEFAULT\",\"af_sub5\":null,\"af_sub4\":null,\"af_cpi\":null,\"af_sub3\":null,\"af_sub2\":null,\"af_status\":\"Non-organic\"}"
        }
    
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: json!.data(using: .utf8)!, options: [])
            return jsonObject as! [String: Any]
        } catch {
            return [:]
        }
    }
}

