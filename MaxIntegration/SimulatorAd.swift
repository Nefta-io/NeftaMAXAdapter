//
//  SimulatorAd.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 10. 11. 25.
//

public class SimulatorAd : UIView {
 
    @IBOutlet weak var _title: UILabel!
    @IBOutlet weak var _closeButton: UIButton!
    
    private var _onShow: (() -> Void)? = nil
    private var _onClick: (() -> Void)? = nil
    private var _onReward: (() -> Void)? = nil
    
    public func Show(title: String, onShow: @escaping (() -> Void), onClick: @escaping (() -> Void), onReward: (() -> Void)?, onClose: @escaping (() -> Void)) {
        _title.text = title
        
        _onShow = onShow
        _onClick = onClick
        _onReward = onReward

        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
        
        _closeButton.addAction(UIAction { _ in
            self.isHidden = true
            onClose()
        }, for: .touchUpInside)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self._onShow!()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if !self.isHidden, let onReward = self._onReward {
                onReward()
                self._onReward = nil
            }
        }
        
        isHidden = false
    }
    
    @objc func viewTapped() {
        _onClick!()
    }
}
