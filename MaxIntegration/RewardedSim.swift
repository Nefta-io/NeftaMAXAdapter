//
//  RewardedSim.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 11. 11. 25.
//


public class RewardedSim : UIView {
    public static let AdUnitA = "Rewarded Track A"
    public static let AdUnitB = "Rewarded Track B"
    private let DefaultBackgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    private let DefaultColor = UIColor(red: 0.6509804, green: 0.1490196, blue: 0.7490196, alpha: 1.0)
    private let FillColor = UIColor.green
    private let NoFillColor = UIColor.red
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
        case Shown
    }
    
    public class Track : NSObject, MARewardedAdDelegate, MAAdDelegate, MAAdRevenueDelegate {
        private let _controller: RewardedSim
        
        public let _adUnitId: String
        public var _rewarded: SimRewarded!
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        
        public init(controller: RewardedSim ,adUnitId: String) {
            _controller = controller
            _adUnitId = adUnitId
            
            super.init()
            
            Reset()
        }
        
        public func Reset() {
            if let oldRewarded = _rewarded {
                oldRewarded.delegate = nil
                oldRewarded.revenueDelegate = nil
            }
            
            _rewarded = SimRewarded.shared(withAdUnitIdentifier: _adUnitId)
            _rewarded.delegate = self
            _rewarded.revenueDelegate = self
            
            _state = State.Idle
            _insight = nil
            _revenue = -1
        }
        
        public func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withRewarded: _rewarded, error: error)
            
            _controller.Log("Load failed \(adUnitIdentifier): \(error)")
            
            OnLoadFail()
        }
        
        public func OnLoadFail() {
            retryLoad()
            
            _controller.OnTrackLoad(false)
        }
        
        public func didLoad(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withRewarded: _rewarded, ad: ad)
            
            _controller.Log("Loaded \(ad) at: \(ad.revenue)")
            
            _insight = nil
            _revenue = ad.revenue
            _state = State.Ready
            
            _controller.OnTrackLoad(true)
        }
        
        public func retryLoad() {
            DispatchQueue.main.asyncAfter(deadline: .now() + ALNeftaMediationAdapter.GetRetryDelayInSeconds(insight: _insight)) {
                self._state = State.Idle
                self._controller.RetryLoadTracks()
            }
        }
        
        public func didPayRevenue(for ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationImpression(ad)
            
            _controller.Log("didPayRevenueForAd \(ad.adUnitIdentifier) revenue: \(ad.revenue) network: \(ad.networkName)")
        }
        
        public func didClick(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationClick(ad)
            
            _controller.Log("didClick \(ad)")
        }
        
        public func didFail(toDisplay ad: MAAd, withError error: MAError) {
            RewardedSim.Instance.Log("didFail \(ad)")
            
            _state = State.Idle
            _controller.RetryLoadTracks()
        }
        
        public func didDisplay(_ ad: MAAd) {
            _controller.Log("didDisplay \(ad)")
        }
        
        public func didRewardUser(for ad: MAAd, with reward: MAReward) {
            _controller.Log("didRewardUser \(ad) \(reward)")
        }

        public func didHide(_ ad: MAAd) {
            _controller.Log("didHide \(ad)")
            
            _state = State.Idle
            _controller.RetryLoadTracks()
        }
    }
    
    private var _trackA: Track!
    private var _trackB: Track!
    private var _isFirstResponseReceived = false
    
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
    
    public static var Instance: RewardedSim!
    
    private func LoadTracks() {
        LoadTrack(track: _trackA, otherState: _trackB._state)
        LoadTrack(track: _trackB, otherState: _trackA._state)
    }
    
    private func LoadTrack(track: Track, otherState: State) {
        if track._state == .Idle {
            if otherState == .LoadingWithInsights || otherState == .Shown {
                if (_isFirstResponseReceived) {
                    LoadDefault(track: track)
                }
            } else {
                GetInsightsAndLoad(track: track)
            }
        }
    }
    
    private func GetInsightsAndLoad(track: Track) {
        track._state = .LoadingWithInsights
        
        NeftaPlugin._instance!.GetInsights(Insights.Rewarded, previousInsight: track._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._rewarded {
                track._insight = insight
                let bidFloor = String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), insight._floorPrice)

                track._rewarded.setExtraParameterForKey("disable_auto_retries", value: "true")
                track._rewarded.setExtraParameterForKey("jC7Fp", value: bidFloor)
                
                ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: track._rewarded, insight: insight)
                
                self.Log("Loading \(track._adUnitId) as Optimized with floor: \(bidFloor)")
                track._rewarded.load()
            } else {
                track.OnLoadFail()
            }
        })
    }
    
    private func LoadDefault(track: Track) {
        track._state = .Loading
        
        Log("Loading \(track._adUnitId) as Default")
        
        track._rewarded.setExtraParameterForKey("disable_auto_retries", value: "false")
        track._rewarded.setExtraParameterForKey("jC7Fp", value: "")
        
        ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: track._rewarded)

        track._rewarded.load()
    }
    
    private func OnNewSession() {
        Log("Rewarded on new session")
        
        _trackA.Reset()
        _trackB.Reset()
        
        UpdateShowButton()
        _isFirstResponseReceived = false
        RetryLoadTracks()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        RewardedSim.Instance = self
        
        _trackA = Track(controller: self, adUnitId: RewardedSim.AdUnitA)
        _trackB = Track(controller: self, adUnitId: RewardedSim.AdUnitB)
        ALNeftaMediationAdapter.AddNewSessionCallback(callback: OnNewSession)
        
        ToggleTrackA(isOn: false)
        _aFill2.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackA, isHigh: true)
        }, for: .touchUpInside)
        _aFill1.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackA, isHigh: false)
        }, for: .touchUpInside)
        _aNoFill.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackA, status: 2)
        }, for: .touchUpInside)
        _aOther.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackA, status: 0)
        }, for: .touchUpInside)
        
        ToggleTrackB(isOn: false)
        _bFill2.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackB, isHigh: true)
        }, for: .touchUpInside)
        _bFill1.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackB, isHigh: false)
        }, for: .touchUpInside)
        _bNoFill.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackB, status: 2)
        }, for: .touchUpInside)
        _bOther.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackB, status: 0)
        }, for: .touchUpInside)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    public override var isHidden: Bool {
        didSet {
            if isHidden {
                if let loadSwitch = _loadSwitch {
                    loadSwitch.setOn(false, animated: false)
                }
            }
        }
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            LoadTracks()
        }
    }
    
    @objc private func OnShowClick() {
        var isShown = false
        if _trackA._state == .Ready {
            if _trackB._state == .Ready && _trackB._revenue > _trackA._revenue {
                isShown = TryShow(track: _trackB)
            }
            if !isShown {
                isShown = TryShow(track: _trackA)
            }
        }
        if !isShown && _trackB._state == .Ready {
            isShown = TryShow(track: _trackB)
        }
        
        UpdateShowButton()
    }
    
    private func TryShow(track: Track) -> Bool {
        track._revenue = -1
        if track._rewarded.isReady {
            track._state = .Shown
            track._rewarded.show()
            return true
        }
        track._state = .Idle
        RetryLoadTracks()
        return false
    }
    
    private func RetryLoadTracks() {
        if _loadSwitch.isOn {
            LoadTracks()
        }
    }
    
    private func OnTrackLoad(_ success: Bool) {
        if success {
            UpdateShowButton()
        }
        
        _isFirstResponseReceived = true
        RetryLoadTracks()
    }
    
    private func UpdateShowButton() {
        _showButton.isEnabled = _trackA._state == .Ready || _trackB._state == .Ready
    }
    
    private func Log(_ log: String) {
        _status.text = log
        ViewController._log.notice("NeftaPluginMAX Simulator: \(log, privacy: .public)")
    }
    
    public class SimRewarded : SMARewardedAd {
        public var _adUnitId: String!
        public var _ad: MAAd?
        public var _floor: Double = -1.0
        public var _delegate: MARewardedAdDelegate?
        
        public override class func shared(withAdUnitIdentifier adUnitId: String) -> Self {
            let a = super.shared(withAdUnitIdentifier: adUnitId)
            a._adUnitId = adUnitId
            a._floor = -1
            return a
        }
        
        deinit {
            _ad = nil
            
            if _adUnitId == InterstitialSim.AdUnitA {
                RewardedSim.Instance.ToggleTrackA(isOn: false)
                RewardedSim.Instance.SetStatusA("")
            } else {
                RewardedSim.Instance.ToggleTrackB(isOn: false)
                RewardedSim.Instance.SetStatusB("")
            }
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
            guard let ad = _ad else {
                return
            }
            _ad = nil
            
            if _adUnitId == RewardedSim.AdUnitA {
                RewardedSim.Instance.ToggleTrackA(isOn: false)
                RewardedSim.Instance.SetStatusA("Showing A")
            } else {
                RewardedSim.Instance.ToggleTrackB(isOn: false)
                RewardedSim.Instance.SetStatusB("Showing B")
            }
            
            NDebug.Open(
                title: "Rewarded",
                viewController: GetUIViewController(),
                onShow: {
                    self.delegate!.didDisplay(ad)
                    (self.delegate! as! MAAdRevenueDelegate).didPayRevenue(for: ad)
                },
                onClick: { self.delegate!.didClick(ad) },
                onClose: { self.delegate!.didHide(ad) },
                onReward: { self.delegate!.didRewardUser(for: ad, with: MAReward(amount: 1, label: "reward")) }
            )
        }
        
        private func GetUIViewController() -> UIViewController {
            let keyWindow = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }

            return (keyWindow!.rootViewController?.presentedViewController ?? keyWindow!.rootViewController)!
        }
        
        public override func setExtraParameterForKey(_ key: String, value: String?) {
            if key == "jC7Fp" {
                if value == "" {
                    _floor = -1
                } else {
                    _floor = Double(value!)!
                }
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
    
    func SimOnAdLoadedEvent(request: Track, isHigh: Bool) {
        let revenue = isHigh ? 0.002 : 0.001
        if request._rewarded._ad != nil {
            request._rewarded._ad = nil
            
            if request._adUnitId == InterstitialSim.AdUnitA {
                if isHigh {
                    _aFill2.tintColor = DefaultColor
                    _aFill2.backgroundColor = DefaultColor
                    _aFill2.isEnabled = false
                } else{
                    _aFill1.tintColor = DefaultColor
                    _aFill1.backgroundColor = DefaultColor
                    _aFill1.isEnabled = false
                }
            } else {
                if isHigh {
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
        
        let ad = SimMAAd.create()
        ad.simAdUnitIdentifier = request._adUnitId
        ad.simFormat = MAAdFormat.rewarded
        ad.simNetworkName = "simulator"
        ad.simRevenue = revenue
        ad.simRevenuePrecision = "exact"
        ad.simWaterfall = SimMAAd.getWaterfall("simulator waterfall", testName: "test name", responses: [NSNumber(value: MAAdLoadState.adLoaded.rawValue), NSNumber(value: MAAdLoadState.adLoadNotAttempted.rawValue)])
        
        if request._adUnitId == RewardedSim.AdUnitA {
            ToggleTrackA(isOn: false)
            if isHigh {
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
            if isHigh {
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
        
        request._rewarded.SimLoad(ad: ad)
    }
    
    func SimOnAdFailedEvent(request: Track, status: Int) {
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
        
        let error = SMAError.create(status, message: "simulator error")
        error.simWaterfall = SimMAAd.getWaterfall("sim waterfall", testName: "sim test name", responses: [NSNumber(value: MAAdLoadState.adFailedToLoad.rawValue), NSNumber(value: MAAdLoadState.adFailedToLoad.rawValue)])
        request._rewarded.SimFailLoad(error: error)
    }
    
    public func SetStatusA(_ status: String) {
        _aStatus.text = status
    }
    
    public func SetStatusB(_ status: String) {
        _bStatus.text = status
    }
}
