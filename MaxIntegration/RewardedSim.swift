//
//  RewardedSim.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 11. 11. 25.
//


public class RewardedSim : UIView {
    public static let AdUnitA = "Track A"
    public static let AdUnitB = "Track B"
    private let TimeoutInSeconds = 5
    private let DefaultBackgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    private let DefaultColor = UIColor(red: 0.6509804, green: 0.1490196, blue: 0.7490196, alpha: 1.0)
    private let FillColor = UIColor.green
    private let NoFillColor = UIColor.red
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
    }
    
    public class AdRequest : NSObject, MARewardedAdDelegate, MAAdRevenueDelegate {
        public let _adUnitId: String
        public var _rewarded: SimRewarded? = nil
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        public var _consecutiveAdFails: Int = 0
        
        public init(adUnitId: String) {
            _adUnitId = adUnitId
        }
        
        public func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withRewarded: _rewarded!, error: error)
            
            RewardedSim.Instance.Log("Load failed \(adUnitIdentifier): \(error)")
            
            _rewarded = nil
            _consecutiveAdFails += 1
            retryLoad()
            
            RewardedSim.Instance.OnTrackLoad(false)
        }
        
        public func didLoad(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withRewarded: _rewarded!, ad: ad)
            
            RewardedSim.Instance.Log("Loaded \(ad) at: \(ad.revenue)")
            
            _insight = nil
            _consecutiveAdFails = 0
            _revenue = ad.revenue
            _state = State.Ready
            
            RewardedSim.Instance.OnTrackLoad(true)
        }
        
        public func retryLoad() {
            // As per MAX recommendations, retry with exponentially higher delays up to 64s
            // In case you would like to customize fill rate / revenue please contact our customer support
            let delayInSeconds = [0, 2, 4, 8, 16, 32, 64][min(_consecutiveAdFails, 6)]
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayInSeconds)) {
                self._state = State.Idle
                RewardedSim.Instance.RetryLoading()
            }
        }
        
        public func didPayRevenue(for ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationImpression(ad)
            
            RewardedSim.Instance.Log("didPayRevenueForAd \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
        }
        
        public func didClick(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationClick(ad)
            
            RewardedSim.Instance.Log("didClick \(ad)")
        }
        
        public func didFail(toDisplay ad: MAAd, withError error: MAError) {
            RewardedSim.Instance.Log("didFail \(ad)")
        }
        
        public func didDisplay(_ ad: MAAd) {
            RewardedSim.Instance.Log("didDisplay \(ad)")
        }
        
        public func didRewardUser(for ad: MAAd, with reward: MAReward) {
            RewardedSim.Instance.Log("didRewardUser \(ad) \(reward)")
        }

        public func didHide(_ ad: MAAd) {
            RewardedSim.Instance.Log("didHide \(ad)")
            
            RewardedSim.Instance.RetryLoading()
        }
    }
    
    private var _adRequestA: AdRequest
    private var _adRequestB: AdRequest
    private var _isFirstResponseRecieved = false
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    
    @IBOutlet weak var _aFill2: UIButton!
    @IBOutlet weak var _aFill1: UIButton!
    @IBOutlet weak var _aNoFill: UIButton!
    @IBOutlet weak var _aOther: UIButton!
    @IBOutlet weak var _aStatus: UILabel!
    
    @IBOutlet weak var _bFill2: UIButton!
    @IBOutlet weak var _bFill1: UIButton!
    @IBOutlet weak var _bNoFill: UIButton!
    @IBOutlet weak var _bOther: UIButton!
    @IBOutlet weak var _bStatus: UILabel!
    
    @IBOutlet weak var _simulatorAd: SimulatorAd!
    
    public static var Instance: RewardedSim!
    
    private func StartLoading() {
        Load(request: _adRequestA, otherState: _adRequestB._state)
        Load(request: _adRequestB, otherState: _adRequestA._state)
    }
    
    private func Load(request: AdRequest, otherState: State) {
        if request._state == State.Idle {
            if otherState != State.LoadingWithInsights {
                GetInsightsAndLoad(adRequest: request)
            } else if (_isFirstResponseRecieved) {
                LoadDefault(adRequest: request)
            }
        }
    }
    
    private func GetInsightsAndLoad(adRequest: AdRequest) {
        adRequest._state = State.LoadingWithInsights
        
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, previousInsight: adRequest._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._rewarded {
                adRequest._insight = insight
                let bidFloor = String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), insight._floorPrice)
                adRequest._rewarded = SimRewarded.shared(withAdUnitIdentifier: adRequest._adUnitId)
                adRequest._rewarded!.delegate = adRequest
                adRequest._rewarded!.setExtraParameterForKey("disable_auto_retries", value: "true")
                adRequest._rewarded!.setExtraParameterForKey("jC7Fp", value: bidFloor)
                
                ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: adRequest._rewarded!, insight: insight)
                
                self.Log("Loading \(adRequest._adUnitId) as Optimized with floor: \(bidFloor)")
                adRequest._rewarded!.load()
            } else {
                adRequest._consecutiveAdFails += 1
                self._isFirstResponseRecieved = true
                adRequest.retryLoad()
            }
        }, timeout: TimeoutInSeconds)
    }
    
    private func LoadDefault(adRequest: AdRequest) {
        adRequest._state = State.Loading
        
        Log("Loading \(adRequest._adUnitId) as Default")
        
        adRequest._rewarded = SimRewarded.shared(withAdUnitIdentifier: adRequest._adUnitId)
        adRequest._rewarded!.delegate = adRequest
        
        ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: adRequest._rewarded!)

        adRequest._rewarded!.load()
    }
    
    required init?(coder: NSCoder) {
        _adRequestA = AdRequest(adUnitId: RewardedSim.AdUnitA)
        _adRequestB = AdRequest(adUnitId: RewardedSim.AdUnitB)
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        _adRequestA = AdRequest(adUnitId: RewardedSim.AdUnitA)
        _adRequestB = AdRequest(adUnitId: RewardedSim.AdUnitB)
        super.init(frame: frame)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        RewardedSim.Instance = self
        
        ToggleTrackA(isOn: false)
        _aFill2.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._adRequestA, revenue: 2)
        }, for: .touchUpInside)
        _aFill1.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._adRequestA, revenue: 1)
        }, for: .touchUpInside)
        _aNoFill.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._adRequestA, status: 2)
        }, for: .touchUpInside)
        _aOther.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._adRequestA, status: 0)
        }, for: .touchUpInside)
        
        ToggleTrackB(isOn: false)
        _bFill2.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._adRequestB, revenue: 2)
        }, for: .touchUpInside)
        _bFill1.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._adRequestB, revenue: 1)
        }, for: .touchUpInside)
        _bNoFill.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._adRequestB, status: 2)
        }, for: .touchUpInside)
        _bOther.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._adRequestB, status: 0)
        }, for: .touchUpInside)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            StartLoading()
        }
    }
    
    @objc private func OnShowClick() {
        var isShown = false
        if _adRequestA._state == State.Ready {
            if _adRequestB._state == State.Ready && _adRequestB._revenue > _adRequestA._revenue {
                isShown = TryShow(adRequest: _adRequestB)
            }
            if !isShown {
                isShown = TryShow(adRequest: _adRequestA)
            }
        }
        if !isShown && _adRequestB._state == State.Ready {
            isShown = TryShow(adRequest: _adRequestB)
        }
        
        UpdateShowButton()
    }
    
    private func TryShow(adRequest: AdRequest) -> Bool {
        adRequest._state = State.Idle
        adRequest._revenue = -1

        if adRequest._rewarded!.isReady {
            adRequest._rewarded!.show()
            return true
        }
        RetryLoading()
        return false
    }
    
    private func RetryLoading() {
        if _loadSwitch.isOn {
            StartLoading()
        }
    }
    
    private func OnTrackLoad(_ success: Bool) {
        if success {
            UpdateShowButton()
        }
        
        _isFirstResponseRecieved = true
        RetryLoading()
    }
    
    private func UpdateShowButton() {
        _showButton.isEnabled = _adRequestA._state == State.Ready || _adRequestB._state == State.Ready
    }
    
    private func Log(_ log: String) {
        _status.text = log
        ViewController._log.info("NeftaPluginMAX Simulator: \(log, privacy: .public)")
    }
    
    public class SimRewarded : SMARewardedAd {
        public var _adUnitId: String!
        public var _ad: MAAd?
        public var _floor: Double = -1.0
        public var _delegate: MARewardedAdDelegate?
        
        public override class func shared(withAdUnitIdentifier adUnitId: String) -> Self {
            let a = super.shared(withAdUnitIdentifier: adUnitId)!
            a._adUnitId = adUnitId
            a._floor = -1
            return a
        }
   
        public override func load() {
            let status = "\(_adUnitId!) loading \(_floor >= 0 ? "as Optimized" : "as Default")"
            
            if _adUnitId == RewardedSim.AdUnitA {
                RewardedSim.Instance.ToggleTrackA(isOn: true)
                RewardedSim.Instance.SetStatusA(status)
            } else {
                RewardedSim.Instance.ToggleTrackB(isOn: true)
                RewardedSim.Instance.SetStatusB(status)
            }
        }
        
        public override func show() {
            (delegate! as! MAAdRevenueDelegate).didPayRevenue(for: _ad!)
            
            RewardedSim.Instance.Show(title: "Rewarded",
                onShow: { self.delegate!.didDisplay(self._ad!) },
                onClick: { self.delegate!.didClick(self._ad!) },
                onReward: { self.delegate!.didRewardUser(for: self._ad!, with: MAReward(amount: 1, label: "reward")) },
                onClose: { self.delegate!.didHide(self._ad!) }
            )
            
            if _adUnitId == RewardedSim.AdUnitA {
                RewardedSim.Instance.SetStatusA("Showing A")
            } else {
                RewardedSim.Instance.SetStatusB("Showing B")
            }
        }
        
        public override func setExtraParameterForKey(_ key: String, value: String?) {
            if key == "jC7Fp" {
                _floor = Double(value!)!
            }
        }
        
        public func SimLoad(ad: MAAd) {
            _ad = ad
            delegate!.didLoad(_ad!)
        }
        
        public func SimFailLoad(error: MAError) {
            delegate!.didFailToLoadAd(forAdUnitIdentifier: _adUnitId, withError: error)
        }
        
        public override var isReady: Bool {
            return _ad != nil
        }
        
        public override var adUnitIdentifier: String {
            return _adUnitId
        }
        
        public override var delegate: (any MARewardedAdDelegate)? {
            get {
                return _delegate
            }
            set {
                _delegate = newValue
            }
        }
    }
    
    private func ToggleTrackA(isOn: Bool) {
        _aFill2.isEnabled = isOn
        _aFill1.isEnabled = isOn
        _aNoFill.isEnabled = isOn
        _aOther.isEnabled = isOn
        
        if isOn {
            _aFill2.tintColor = DefaultColor
            _aFill2.backgroundColor = DefaultBackgroundColor
            _aFill1.tintColor = DefaultColor
            _aFill1.backgroundColor = DefaultBackgroundColor
            _aNoFill.tintColor = DefaultColor
            _aNoFill.backgroundColor = DefaultBackgroundColor
            _aOther.tintColor = DefaultColor
            _aOther.backgroundColor = DefaultBackgroundColor
        }
    }
    
    private func ToggleTrackB(isOn: Bool) {
        _bFill2.isEnabled = isOn
        _bFill1.isEnabled = isOn
        _bNoFill.isEnabled = isOn
        _bOther.isEnabled = isOn
        
        if isOn {
            _bFill2.tintColor = DefaultColor
            _bFill2.backgroundColor = DefaultBackgroundColor
            _bFill1.tintColor = DefaultColor
            _bFill1.backgroundColor = DefaultBackgroundColor
            _bNoFill.tintColor = DefaultColor
            _bNoFill.backgroundColor = DefaultBackgroundColor
            _bOther.tintColor = DefaultColor
            _bOther.backgroundColor = DefaultBackgroundColor
        }
    }
    
    func SimOnAdLoadedEvent(request: AdRequest, revenue: Double) {
        if request._rewarded!._ad != nil {
            request._rewarded!._ad = nil
            
            if request._adUnitId == InterstitialSim.AdUnitA {
                if revenue >= 2 {
                    _aFill2.tintColor = DefaultColor
                    _aFill2.backgroundColor = DefaultColor
                    _aFill2.isEnabled = false
                } else{
                    _aFill1.tintColor = DefaultColor
                    _aFill1.backgroundColor = DefaultColor
                    _aFill1.isEnabled = false
                }
            } else {
                if revenue >= 2 {
                    _bFill2.tintColor = DefaultColor
                    _bFill2.backgroundColor = DefaultColor
                    _bFill2.isEnabled = false
                } else{
                    _bFill1.tintColor = DefaultColor
                    _bFill1.backgroundColor = DefaultColor
                    _bFill1.isEnabled = false
                }
            }
            return
        }
        
        let ad = SimMAAd.create()!
        ad.simAdUnitIdentifier = request._adUnitId
        ad.simFormat = MAAdFormat.rewarded
        ad.simNetworkName = "simulator"
        ad.simRevenue = revenue
        ad.simRevenuePrecision = "exact"
        
        if request._adUnitId == RewardedSim.AdUnitA {
            ToggleTrackA(isOn: false)
            if revenue >= 2 {
                _aFill2.tintColor = FillColor
                _aFill2.backgroundColor = FillColor
                _aFill2.isEnabled = true
            } else {
                _aFill1.tintColor = FillColor
                _aFill1.backgroundColor = FillColor
                _aFill1.isEnabled = true
            }
            SetStatusA("\(request._adUnitId) loaded \(revenue)")
        } else {
            ToggleTrackB(isOn: false)
            if revenue >= 2 {
                _bFill2.tintColor = FillColor
                _bFill2.backgroundColor = FillColor
                _bFill2.isEnabled = true
            } else {
                _bFill1.tintColor = FillColor
                _bFill1.backgroundColor = FillColor
                _bFill1.isEnabled = true
            }
            SetStatusB("\(request._adUnitId) loaded \(revenue)")
        }
        
        request._rewarded!.SimLoad(ad: ad)
    }
    
    func SimOnAdFailedEvent(request: AdRequest, status: Int) {
        if request._adUnitId == RewardedSim.AdUnitA {
            if status == 2 {
                _aNoFill.tintColor = NoFillColor
                _aNoFill.backgroundColor = NoFillColor
            } else {
                _aOther.tintColor = NoFillColor
                _aOther.backgroundColor = NoFillColor
            }
            ToggleTrackA(isOn: false)
        } else {
            if status == 2 {
                _bNoFill.tintColor = NoFillColor
                _bNoFill.backgroundColor = NoFillColor
            } else {
                _bOther.tintColor = NoFillColor
                _bOther.backgroundColor = NoFillColor
            }
            ToggleTrackB(isOn: false)
        }
        
        let error = status == 2 ? MAAdapterError.noFill : MAAdapterError.noConnection
        request._rewarded!.SimFailLoad(error: error)
    }
    
    public func SetStatusA(_ status: String) {
        _aStatus.text = status
    }
    
    public func SetStatusB(_ status: String) {
        _bStatus.text = status
    }
    
    public func Show(title: String, onShow: @escaping (() -> Void), onClick: @escaping (() -> Void), onReward: (() -> Void)!, onClose: @escaping (() -> Void)) {
        _simulatorAd.Show(title: title, onShow: onShow, onClick: onClick, onReward: onReward, onClose: onClose)
    }
}
