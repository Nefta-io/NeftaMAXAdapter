//
//  AttributionAppsFlyer.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 16. 10. 26.
//
import AppsFlyerLib

public class AttributionAppsFlyer : UIResponder, AppsFlyerLibDelegate {
    
    public func Sample() {
        AppsFlyerLib.shared().appsFlyerDevKey = "key"
        AppsFlyerLib.shared().appleAppID = "apple_app_id"
        AppsFlyerLib.shared().delegate = self
    }
    
    public func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        let mmpId = AppsFlyerLib.shared().getAppsFlyerUID()
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
        
        NeftaPlugin.OnAttributionChanged(mmp: .AppsFlyer, mmpId: mmpId, network: network, campaign: campaign, costType: costType, cost: cost, costCurrency: "USD")
    }
    
    public func onConversionDataFail(_ error: Error) {}
}
