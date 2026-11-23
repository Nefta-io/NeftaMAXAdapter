//
//  AttributionAdjust.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 16. 10. 26.
//
import Adjust
import NeftaSDK

public class AttributionAdjust : UIResponder, AdjustDelegate {
    
    public func Sample() {
        guard let adjustConfig = ADJConfig(appToken: "token", environment: ADJEnvironmentSandbox) else {
            print("Failed to create Adjust config")
            return
        }
        
        adjustConfig.delegate = self
        Adjust.appDidLaunch(adjustConfig)
    }
    
    public func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let data = attribution else {
            return
        }
        
        NeftaPlugin.OnAttributionChanged(mmp: .Adjust, mmpId: data.adid, network: data.network, campaign: data.campaign, costType: data.costType, cost: data.costAmount?.doubleValue ?? 0.0, costCurrency: data.costCurrency)
    }
}
