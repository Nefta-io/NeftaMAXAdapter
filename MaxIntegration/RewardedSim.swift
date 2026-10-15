//
//  RewardedSim.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 11. 11. 25.
//


public class RewardedSim : UIView {
    public static let AdUnitA = "Rewarded Track A"
    public static let AdUnitB = "Rewarded Track B"
    public static let AdUnitD = "Rewarded Track D"
    private let DefaultBackgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    private let DefaultColor = UIColor(red: 0.6509804, green: 0.1490196, blue: 0.7490196, alpha: 1.0)
    private let FillColor = UIColor.green
    private let NoFillColor = UIColor.red
    
    public enum State {
        case Idle
        case Loading
        case Ready
        case Shown
        case Delay
    }
    
    public class Track : NSObject, MARewardedAdDelegate, MAAdDelegate, MAAdRevenueDelegate {
        private let _controller: RewardedSim
        
        public let _adUnitId: String
        public let _isOptimized: Bool
        public let _rewarded: SimRewarded!
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        
        public init(controller: RewardedSim ,adUnitId: String, isOptimized: Bool) {
            _controller = controller
            _adUnitId = adUnitId
            _isOptimized = isOptimized
            
            _rewarded = SimRewarded.shared(withAdUnitIdentifier: _adUnitId)
            
            super.init()
            
            _rewarded.delegate = self
            _rewarded.revenueDelegate = self
        }
        
        public func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withRewarded: _rewarded, error: error)
            
            _controller.Log("Load failed \(adUnitIdentifier): \(error)")
            
            _controller.OnTrackLoad(track: self, success: false)
        }
        
        public func didLoad(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withRewarded: _rewarded, ad: ad)
            
            _controller.Log("Loaded \(ad) at: \(ad.revenue)")
            
            _insight = nil
            _revenue = ad.revenue
            _state = State.Ready
            
            _controller.OnTrackLoad(track: self, success: true)
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
            _controller.ContinueLoading()
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
            _controller.ContinueLoading()
        }
    }
    
    private var _tracks: [Track]!
    private var _isFirstRequest = true
    private var _isFirstOptimizedResponseReceived = false
    private var _isGlobalCooldown: Int = 0
    private var _isOptimized: Bool = false
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    
    private var _fill3: [UIButton]!
    private var _fill2: [UIButton]!
    private var _fill1: [UIButton]!
    private var _noFill: [UIButton]!
    private var _other: [UIButton]!
    private var _statuses: [UILabel]!
    
    public static var Instance: RewardedSim!
    
    public func SetOptimized(isOptimized: Bool) {
        _isOptimized = isOptimized
        isHidden = false
    }
    
    private func Load() {
        if _isFirstRequest && _isOptimized {
            Load(track: _tracks[1])
            
            let stopWaitingForFirstResponseAfter = NeftaPlugin._instance!._state._firstResponseTimeoutRewardedInMs
            if stopWaitingForFirstResponseAfter > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(stopWaitingForFirstResponseAfter) * 0.001) {
                    if !self._isFirstOptimizedResponseReceived {
                        self._isFirstOptimizedResponseReceived = true
                        if self._tracks.count > 2 && self._tracks[2]._state == .Idle {
                            self.Load(track: self._tracks[2])
                        }
                        if NeftaPlugin._instance!._state._backfillTrackDelayInMs < 0 && self._tracks[0]._state == .Idle {
                            self.Load(track: self._tracks[0])
                        }
                    }
                }
            }
            
            let backFillTrackDelayInMs = NeftaPlugin._instance!._state._backfillTrackDelayInMs
            if (backFillTrackDelayInMs == 0) {
                Load(track: _tracks[0])
            } else if (backFillTrackDelayInMs > 0) {
                _tracks[0]._state = .Delay
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(backFillTrackDelayInMs) * 0.001) {
                    self.Load(track: self._tracks[0])
                }
            }
            
            _isFirstRequest = false
        } else {
            ContinueLoading()
        }
    }
    
    private func Load(track: Track) {
        track._state = .Loading
        
        if track._isOptimized {
            NeftaPlugin._instance!.GetInsights(Insights.Rewarded, previousInsight: track._insight, callback: { insights in
                self.Log("Load with insights: \(insights)")
                if let insight = insights._rewarded {
                    track._insight = insight
                    var bidFloor = ""
                    if insight._floorPrice >= 0 {
                        bidFloor = String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), insight._floorPrice)
                    }
                    
                    track._rewarded.setExtraParameterForKey("jC7Fp", value: bidFloor)
                    
                    ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: track._rewarded, insight: insight)
                    
                    self.Log("Loading \(track._adUnitId) as Optimized with floor: \(bidFloor)")
                    track._rewarded.load()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(NeftaPlugin.GetRetryDelayInSeconds(insight: track._insight, adUnitId: track._adUnitId))) {
                        track._state = State.Idle
                        self.ContinueLoading()
                    }
                }
            })
        } else {
            ALNeftaMediationAdapter.onExternalMediationRequest(withRewarded: track._rewarded)
            
            Log("Loading \(track._adUnitId) as Default")
            track._rewarded.load()
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        RewardedSim.Instance = self
        
        _tracks = [
            Track(controller: self, adUnitId: RewardedSim.AdUnitD, isOptimized: false),
            Track(controller: self, adUnitId: RewardedSim.AdUnitA, isOptimized: true),
            Track(controller: self, adUnitId: RewardedSim.AdUnitB, isOptimized: true)
        ]
        
        _statuses = [
            viewWithTag(103) as! UILabel,
            viewWithTag(101) as! UILabel,
            viewWithTag(102) as! UILabel
        ]
        _fill3 = [
            viewWithTag(203) as! UIButton,
            viewWithTag(201) as! UIButton,
            viewWithTag(202) as! UIButton
        ]
        _fill2 = [
            viewWithTag(303) as! UIButton,
            viewWithTag(301) as! UIButton,
            viewWithTag(302) as! UIButton
        ]
        _fill1 = [
            viewWithTag(403) as! UIButton,
            viewWithTag(401) as! UIButton,
            viewWithTag(402) as! UIButton
        ]
        _noFill = [
            viewWithTag(503) as! UIButton,
            viewWithTag(501) as! UIButton,
            viewWithTag(502) as! UIButton
        ]
        _other = [
            viewWithTag(603) as! UIButton,
            viewWithTag(601) as! UIButton,
            viewWithTag(602) as! UIButton
        ]
        
        for i in 0..<_tracks.count {
            let ti = i
            let track = _tracks[ti]
            ToggleTrack(t: ti, isOn: false)
            _fill3[ti].addAction(UIAction { _ in
                self.SimOnAdLoadedEvent(t: ti, track: track, r: 3)
            }, for: .touchUpInside)
            _fill2[ti].addAction(UIAction { _ in
                self.SimOnAdLoadedEvent(t: ti, track: track, r: 2)
            }, for: .touchUpInside)
            _fill1[ti].addAction(UIAction { _ in
                self.SimOnAdLoadedEvent(t: ti, track: track, r: 1)
            }, for: .touchUpInside)
            _noFill[ti].addAction(UIAction { _ in
                self.SimOnAdFailedEvent(t: ti, track: track, status: 2)
            }, for: .touchUpInside)
            _other[ti].addAction(UIAction { _ in
                self.SimOnAdFailedEvent(t: ti, track: track, status: 0)
            }, for: .touchUpInside)
        }
        
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
            Load()
        }
    }
    
    @objc private func OnShowClick() {
        var isShown = false
        let readyTrack = GetReadyTrack()
        if let trackToShow = readyTrack {
            isShown = TryShow(track: trackToShow)
        }
        if !isShown {
            ContinueLoading()
        }
        let availableTrack = GetReadyTrack()
        _showButton.isEnabled = availableTrack != nil
    }
    
    private func TryShow(track: Track) -> Bool {
        track._revenue = -1
        if track._rewarded.isReady {
            track._state = .Shown
            track._rewarded.show()
            return true
        }
        track._state = .Idle
        return false
    }
    
    public func ContinueOptimized() {
        _isFirstOptimizedResponseReceived = true
        if _tracks[0]._state == .Idle {
            Load(track: _tracks[0])
        }
        
        _isGlobalCooldown += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(NeftaPlugin._instance!._state._globalTrackCooldownInMs) * 0.001) {
            self._isGlobalCooldown -= 1
            if self._isGlobalCooldown <= 0 {
                self._isGlobalCooldown = 0
                self.ContinueLoading()
            }
        }
    }
    
    public func ContinueLoading() {
        if !_loadSwitch.isOn {
            return
        }
        
        if _tracks[0]._state == .Idle {
            Load(track: _tracks[0])
        }
        if _isGlobalCooldown > 0 || !_isOptimized {
            return
        }
        for i in 1..<_tracks.count {
            if _tracks[i]._state == .Loading {
                return
            }
        }
        for i in 1..<_tracks.count {
            if _tracks[i]._state == .Idle {
                Load(track: _tracks[i])
                return
            }
        }
    }
    
    private func OnTrackLoad(track: Track, success: Bool) {
        if success {
            _showButton.isEnabled = true
        } else {
            track._state = .Delay
            let delay = Double(NeftaPlugin.GetRetryDelayInSeconds(insight: track._insight, adUnitId: track._adUnitId))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                track._state = State.Idle
                self.ContinueLoading()
            }
        }
        
        if track._isOptimized {
            ContinueOptimized()
        }
    }
    
    private func GetReadyTrack() -> Track? {
        var bestTrack: Track?
        for track in _tracks {
            if track._state == .Ready && (bestTrack == nil || track._revenue > bestTrack!._revenue) {
                bestTrack = track
            }
        }
        return bestTrack
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
            
            var t = 0
            for track in RewardedSim.Instance._tracks {
                if track._adUnitId == _adUnitId {
                    RewardedSim.Instance.ToggleTrack(t: t, isOn: true)
                    RewardedSim.Instance.ToggleTrack(t: t, isOn: false)
                    RewardedSim.Instance.SetStatus(t: t, status: "")
                    break
                }
                t += 1
            }
        }
   
        public override func load() {
            var t = 0
            for track in RewardedSim.Instance._tracks {
                if track._adUnitId == _adUnitId {
                    RewardedSim.Instance.ToggleTrack(t: t, isOn: true)
                    RewardedSim.Instance.SetStatus(t: t, status: "\(_adUnitId!) loading \(_floor >= 0 ? "as Optimized" : "as Default")")
                    break
                }
                t += 1
            }
        }
        
        public override func show() {
            guard let ad = _ad else {
                return
            }
            _ad = nil
            
            var t = 0
            for track in RewardedSim.Instance._tracks {
                if track._adUnitId == _adUnitId {
                    RewardedSim.Instance.ToggleTrack(t: t, isOn: false)
                    RewardedSim.Instance.SetStatus(t: t, status: "Showing \(_adUnitId!)")
                    break
                }
                t += 1
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
    
    public func ToggleTrack(t: Int, isOn: Bool) {
        _fill3[t].isEnabled = isOn
        _fill2[t].isEnabled = isOn
        _fill1[t].isEnabled = isOn
        _noFill[t].isEnabled = isOn
        _other[t].isEnabled = isOn
        
        if isOn {
            _fill3[t].backgroundColor = DefaultBackgroundColor
            _fill3[t].tintColor = DefaultColor
            _fill2[t].backgroundColor = DefaultBackgroundColor
            _fill2[t].tintColor = DefaultColor
            _fill1[t].tintColor = DefaultColor
            _fill1[t].backgroundColor = DefaultBackgroundColor
            _noFill[t].tintColor = DefaultColor
            _noFill[t].backgroundColor = DefaultBackgroundColor
            _other[t].tintColor = DefaultColor
            _other[t].backgroundColor = DefaultBackgroundColor
        }
    }
    
    func SimOnAdLoadedEvent(t: Int, track: Track, r: Int) {
        let revenue = r == 3 ? 0.003 : r == 2 ? 0.002 : 0.001
        if track._rewarded._ad != nil {
            track._rewarded._ad = nil
            
            _fill3[t].tintColor = DefaultColor
            _fill3[t].backgroundColor = DefaultBackgroundColor
            _fill3[t].isEnabled = false
  
            _fill2[t].tintColor = DefaultColor
            _fill2[t].backgroundColor = DefaultBackgroundColor
            _fill2[t].isEnabled = false

            _fill1[t].tintColor = DefaultColor
            _fill1[t].backgroundColor = DefaultBackgroundColor
            _fill1[t].isEnabled = false
            return
        }
        
        let ad = SimMAAd.create()
        ad.simAdUnitIdentifier = track._adUnitId
        ad.simFormat = MAAdFormat.rewarded
        ad.simNetworkName = "simulator"
        ad.simRevenue = revenue
        ad.simRevenuePrecision = "exact"
        ad.simWaterfall = SimMAAd.getWaterfall("simulator waterfall", testName: "test name", responses: [NSNumber(value: MAAdLoadState.adLoaded.rawValue), NSNumber(value: MAAdLoadState.adLoadNotAttempted.rawValue)])
        
        ToggleTrack(t: t, isOn: false)
        if r == 3 {
            _fill3[t].tintColor = FillColor
            _fill3[t].backgroundColor = FillColor
            _fill3[t].isEnabled = true
        } else if r == 2{
            _fill2[t].tintColor = FillColor
            _fill2[t].backgroundColor = FillColor
            _fill2[t].isEnabled = true
        } else {
            _fill1[t].tintColor = FillColor
            _fill1[t].backgroundColor = FillColor
            _fill1[t].isEnabled = true
        }
        SetStatus(t: t, status: "\(track._adUnitId) loaded \(revenue)")
        
        track._rewarded.SimLoad(ad: ad)
    }
    
    func SimOnAdFailedEvent(t: Int, track: Track, status: Int) {
        if status == 2 {
            _noFill[t].tintColor = NoFillColor
            _noFill[t].backgroundColor = NoFillColor
        } else {
            _other[t].tintColor = NoFillColor
            _other[t].backgroundColor = NoFillColor
        }
        ToggleTrack(t: t, isOn: false)
        SetStatus(t: t, status: "\(track._adUnitId) failed")
        
        let error = SMAError.create(status, message: "simulator error")
        error.simWaterfall = SimMAAd.getWaterfall("sim waterfall", testName: "sim test name", responses: [NSNumber(value: MAAdLoadState.adFailedToLoad.rawValue), NSNumber(value: MAAdLoadState.adFailedToLoad.rawValue)])
        track._rewarded.SimFailLoad(error: error)
    }
    
    func SetStatus(t: Int, status: String) {
        _statuses[t].text = status
    }
}
