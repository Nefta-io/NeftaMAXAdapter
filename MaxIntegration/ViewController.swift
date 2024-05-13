//
//  ViewController.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import UIKit

import NeftaSDK
import AppLovinSDK

class ViewController: UIViewController {

    var banner: Banner!
    var interstitial: Interstitial!
    var rewardedVideo: RewardedVideo!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = NeftaPlugin_iOS.Init(appId: "5661184053215232")
        NeftaPlugin_iOS.EnableLogging(enable: true)
        
        ALSdk.shared().settings.isVerboseLoggingEnabled = true
        ALSdk.shared().mediationProvider = "max"
        ALSdk.shared().initializeSdk { (configuration: ALSdkConfiguration) in
       
        }
        
    }
    
    @IBAction func showBanner(_ sender: UIButton) {
        print("showBanner")
        
        banner = Banner()
        banner.show(view: view)
    }
    
    @IBAction func closeBanner(_ sender: UIButton) {
        print("closeBanner")
        
        banner.close()
    }
    
    @IBAction func showInterstitial(_ sender: UIButton) {
        print("showInterstitial")

        interstitial = Interstitial()
        interstitial.show()
    }
    
    @IBAction func showRewardedVideo(_ sender: UIButton) {
        print("showRewardedVideo")

        rewardedVideo = RewardedVideo()
        rewardedVideo.show()
    }
}

