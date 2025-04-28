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

class ViewController: UIViewController {

    var _plugin: NeftaPlugin!
    
    var _banner: Banner!
    var _interstitial: Interstitial!
    var _rewardedVideo: Rewarded!
    
    @IBOutlet weak var _bannerPlaceholder: UIView!
    @IBOutlet weak var _showBanner: UIButton!
    @IBOutlet weak var _hideBanner: UIButton!
    @IBOutlet weak var _loadInterstitial: UIButton!
    @IBOutlet weak var _showInterstitial: UIButton!
    @IBOutlet weak var _loadRewarded: UIButton!
    @IBOutlet weak var _showRewarded: UIButton!
    @IBOutlet weak var _title: UILabel!
    @IBOutlet weak var _bannerStatus: UILabel!
    @IBOutlet weak var _interstitialStatus: UILabel!
    @IBOutlet weak var _rewardedStatus: UILabel!
    
    /* let _interstitialAdUnits = [
        AdUnit(id: "6d318f954e2630a8", cpm: 50.0),
        AdUnit(id: "37146915dc4c7740", cpm: 75.0),
        AdUnit(id: "e5dc3548d4a0913f", cpm: 100.0)
    ]
    
    let _rewardedAdUnits = [
        AdUnit(id: "918acf84edf9c034", cpm: 50.0),
        AdUnit(id: "37163b1a07c4aaa0", cpm: 75.0),
        AdUnit(id: "e0b0d20088d60ec5", cpm: 100.0)
    ]*/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NeftaPlugin.EnableLogging(enable: true)
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.count > 1 {
            NeftaPlugin.SetOverride(url: arguments[1])
        }
        
        _plugin = NeftaPlugin.Init(appId: "5661184053215232")
        _plugin.OnBehaviourInsight = OnBehaviourInsight
        GetBehaviourInsights()

        _title.text = "Nefta Adapter for MAX"
        _banner = Banner(requestNewInsights: GetBehaviourInsights,
                         showButton: _showBanner, hideButton: _hideBanner, status: _bannerStatus, bannerPlaceholder: _bannerPlaceholder)
        _interstitial = Interstitial(requestNewInsights: GetBehaviourInsights,
                                     loadButton: _loadInterstitial, showButton: _showInterstitial, status: _interstitialStatus, onDisplay: OnFullScreenAdDisplay)
        _rewardedVideo = Rewarded(requestNewInsights: GetBehaviourInsights,
                                  loadButton: _loadRewarded, showButton: _showRewarded, status: _rewardedStatus, onDisplay: OnFullScreenAdDisplay)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.checkTrackingAndInitializeMax()
        }
    }
    
    private func GetBehaviourInsights() {
        _plugin.GetBehaviourInsight([
            Banner.InsightFloorPrice,
            Interstitial.InsightAdUnitId, Interstitial.InsightFloorPrice,
            Rewarded.InsightAdUnitId, Rewarded.InsightFloorPrice
        ])
    }
    
    private func OnBehaviourInsight(insights: [String: Insight]) {
        _banner.OnBehaviourInsight(insights: insights)
        _interstitial.OnBehaviourInsight(insights: insights)
        _rewardedVideo.OnBehaviourInsight(insights: insights)
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
        
        max.settings.setExtraParameterForKey("google_max_ad_content_rating", value: "MA")
        max.settings.setExtraParameterForKey("fan_child_directed", value: "false")
        
        max.settings.isVerboseLoggingEnabled = true
        let initConfig = ALSdkInitializationConfiguration(sdkKey: "IAhBswbDpMg9GhQ8NEKffzNrXQP1H4ABNFvUA7ePIz2xmarVFcy_VB8UfGnC9IPMOgpQ3p8G5hBMebJiTHv3P9") { builder in
            builder.mediationProvider = ALMediationProviderMAX
        }
        max.initialize(with: initConfig) { sdkConfig in

        }
    }
    
    private func OnFullScreenAdDisplay(displayed: Bool) {
        _banner.SetAutoRefresh(refresh: !displayed)
    }
}

