//
//  ALNeftaMediationAdapterSwift.swift
//  MaxAdapter
//
//  Created by Tomaz Treven on 23. 1. 25.
//

import AppLovinSDK
import NeftaSDK

class ALNeftaMediationAdapterSwift {
    enum AdTypeSwift : Int{
        case Other = 0
        case Banner = 1
        case Interstitial = 2
        case Rewarded = 3
    }
    
    static func OnExternalAdLoad(_ adType: AdTypeSwift, unitFloorPrice: Float64, calculatedFloorPrice: Float64) {
        NeftaPlugin.OnExternalAdLoad("max", adType: adType.rawValue, unitFloorPrice: unitFloorPrice, calculatedFloorPrice: calculatedFloorPrice, status: 1)
    }
    
    static func OnExternalAdFail(_ adType: AdTypeSwift, unitFloorPrice: Float64, calculatedFloorPrice: Float64, error: MAError) {
        var status = 0
        if (error.code == .noFill) {
            status = 2
        }
        NeftaPlugin.OnExternalAdLoad("max", adType: adType.rawValue, unitFloorPrice: unitFloorPrice, calculatedFloorPrice: calculatedFloorPrice, status: status)
    }
                                 
    static func OnExternalAdShown(_ ad: MAAd) {
        let data = NSMutableDictionary()
        data["mediation_provider"] = "applovin-max"
        data["format"] = ad.format.label
        data["size"] = "\(Int(ad.size.width))x\(Int(ad.size.height))"
        data["ad_unit_id"] = ad.adUnitIdentifier
        data["network_name"] = ad.networkName
        data["creative_id"] = ad.creativeIdentifier
        data["revenue"] = ad.revenue
        data["revenue_precision"] = ad.revenuePrecision
        data["placement_name"] = ad.placement
        data["request_latency"] = Int(ad.requestLatency * 1000)
        data["dsp_name"] = ad.dspName
        data["dsp_id"] = ad.dspIdentifier
        let waterfall = ad.waterfall
        data["waterfall_name"] = waterfall.name
        data["waterfall_test_name"] = waterfall.testName
        let waterfalls = NSMutableArray()
        for other in waterfall.networkResponses {
            var name = other.mediatedNetwork.name
            if name.isEmpty {
                if let n = other.credentials["network_name"] as? String {
                    name = n
                }
            }
            if !name.isEmpty {
                waterfalls.add(name)
            }
        }
        data["waterfall"] = waterfalls
        NeftaPlugin.OnExternalAdShown("max", data: data)
    }
}
