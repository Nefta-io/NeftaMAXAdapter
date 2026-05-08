//
//  RewardedUi.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 9. 05. 24.
//

import Foundation
import AppLovinSDK

class RewardedUi : UIView {
    public static let AdUnitA = "e0b0d20088d60ec5"
    public static let AdUnitB = "918acf84edf9c034"
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    
    private var _logic : Rewarded!
    
    public var IsAutoLoad: Bool = false
    
    public func Init(logic: Rewarded) {
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
        ViewController._log.notice("Rewarded: \(log, privacy: .public)")
    }
}
