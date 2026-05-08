//
//  InterstitialUi.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class InterstitialUi : UIView {
    public static let AdUnitA = "e5dc3548d4a0913f"
    public static let AdUnitB = "6d318f954e2630a8"
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    
    private var _logic : Interstitial!
    
    public var IsAutoLoad: Bool = false
    
    public func Init(logic: Interstitial) {
        _logic = logic
        _logic.Init(ui: self)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        isHidden = false
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        IsAutoLoad = sender.isOn
        if IsAutoLoad {
            _logic.Load()
        }
    }
    
    public func SetAvailable(available: Bool) {
        _showButton.isEnabled = available
    }
    
    @objc private func OnShowClick() {
        _logic.Show()
    }
    
    public func Log(_ log: String) {
        _status.text = log
        ViewController._log.notice("NeftaPluginMAX Interstitial: \(log, privacy: .public)")
    }
}
