//
//  InterstitialSim.swift
//  MaxIntegration
//
//  Created by Tomaz Treven on 5. 11. 25.
//

public class InterstitialSim : UIView {
    public static let AdUnitA = "Inter Track A"
    public static let AdUnitB = "Inter Track B"
    public static let AdUnitD = "Inter Track D"
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
    
    public class Track : NSObject, MAAdDelegate, MAAdRevenueDelegate {
        private let _controller: InterstitialSim
        
        public let _adUnitId: String
        public let _isOptimized: Bool
        public var _interstitial: SimInterstitial!
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        
        public init(controller: InterstitialSim, adUnitId: String, isOptimized: Bool) {
            _controller = controller
            _adUnitId = adUnitId
            _isOptimized = isOptimized

            _interstitial = SimInterstitial(adUnitIdentifier: _adUnitId)
            
            super.init()
            
            _interstitial.delegate = self
            _interstitial.revenueDelegate = self
        }
        
        public func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
            ALNeftaMediationAdapter.onExternalMediationRequestFail(withInterstitial: _interstitial, error: error)
            
            _controller.Log("Load failed \(adUnitIdentifier): \(error)")
            
            _controller.OnTrackLoad(track: self, success: false)
        }
        
        public func didLoad(_ ad: MAAd) {
            ALNeftaMediationAdapter.onExternalMediationRequestLoad(withInterstitial: _interstitial, ad: ad)
            
            _controller.Log("Loaded \(ad) at: \(ad.revenue)")
            
            _insight = nil
            _revenue = ad.revenue
            _state = .Ready
            
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
            InterstitialSim.Instance.Log("didFail \(ad)")
            
            _state = State.Idle
            _controller.ContinueLoading()
        }
        
        public func didDisplay(_ ad: MAAd) {
            _controller.Log("didDisplay \(ad)")
        }

        public func didHide(_ ad: MAAd) {
            _controller.Log("didHide \(ad)")
            
            _state = .Idle
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
    
    public static var Instance: InterstitialSim!
    
    public func SetOptimized(isOptimized: Bool) {
        _isOptimized = isOptimized
        isHidden = false
        
        if let nefta = NeftaPlugin._instance {
            if nefta._state._isDebugEnabled {
                NeftaPlugin._extraParams.setObject(true, forKey: "max_test_mode" as NSString)
                let extra: NSDictionary = ["disable_b2b_ad_unit_ids": "e5dc3548d4a0913f,6d318f954e2630a8,e0b0d20088d60ec5,918acf84edf9c034"]
                NeftaPlugin._extraParams.setObject(extra, forKey: "max_extra" as NSString)
            }
            nefta._state._adProviderCountry = "SIM"
            
            if isOptimized {
                nefta._state._availableNetworks = ["simulator"]
            }
        }
    }
    
    private func Load() {
        if _isFirstRequest && _isOptimized {
            Load(track: _tracks[1])
            
            let stopWaitingForFirstResponseAfter = NeftaPlugin._instance!._state._firstResponseTimeoutInterstitialInMs
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
            NeftaPlugin._instance!.GetInsights(Insights.Interstitial, previousInsight: track._insight, callback: { insights in
                self.Log("Load with insights: \(insights)")
                if let insight = insights._interstitial {
                    track._insight = insight
                    var bidFloor = ""
                    if insight._floorPrice >= 0 {
                        bidFloor = String(format: "%.10f", locale: Locale(identifier: "en_US_POSIX"), insight._floorPrice)
                    }
                    
                    track._interstitial.setExtraParameterForKey("jC7Fp", value: bidFloor)
                    
                    ALNeftaMediationAdapter.onExternalMediationRequest(withInterstitial: track._interstitial, insight: insight)
                    
                    self.Log("Loading \(track._adUnitId) as Optimized with floor: \(bidFloor)")
                    track._interstitial.load()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(NeftaPlugin.GetRetryDelayInSeconds(insight: track._insight, adUnitId: track._adUnitId))) {
                        track._state = State.Idle
                        self.ContinueLoading()
                    }
                }
            })
        } else {
            ALNeftaMediationAdapter.onExternalMediationRequest(withInterstitial: track._interstitial)
            
            Log("Loading \(track._adUnitId) as Default")
            track._interstitial.load()
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        InterstitialSim.Instance = self
        
        _tracks = [
            Track(controller: self, adUnitId: InterstitialSim.AdUnitD, isOptimized: false),
            Track(controller: self, adUnitId: InterstitialSim.AdUnitA, isOptimized: true),
            Track(controller: self, adUnitId: InterstitialSim.AdUnitB, isOptimized: true)
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
        if track._interstitial.isReady {
            track._state = .Shown
            track._interstitial.show()
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
    
    public class SimInterstitial : SMAInterstitialAd {
        public let _adUnitId: String
        public var _ad: MAAd?
        public var _floor: Double = -1.0
        public var _delegate: MAAdDelegate?
        
        public override init(adUnitIdentifier: String) {
            _adUnitId = adUnitIdentifier
            super.init(adUnitIdentifier: adUnitIdentifier)
        }
        
        deinit {
            _ad = nil
            
            var t = 0
            for track in InterstitialSim.Instance._tracks {
                if track._adUnitId == _adUnitId {
                    InterstitialSim.Instance.ToggleTrack(t: t, isOn: true)
                    InterstitialSim.Instance.ToggleTrack(t: t, isOn: false)
                    InterstitialSim.Instance.SetStatus(t: t, status: "")
                    break
                }
                t += 1
            }
        }
        
        public override func load() {
            var t = 0
            for track in InterstitialSim.Instance._tracks {
                if track._adUnitId == _adUnitId {
                    InterstitialSim.Instance.ToggleTrack(t: t, isOn: true)
                    InterstitialSim.Instance.SetStatus(t: t, status: "\(_adUnitId) loading \(_floor >= 0 ? "as Optimized" : "as Default")")
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
            for track in InterstitialSim.Instance._tracks {
                if track._adUnitId == _adUnitId {
                    InterstitialSim.Instance.ToggleTrack(t: t, isOn: false)
                    InterstitialSim.Instance.SetStatus(t: t, status: "Showing \(_adUnitId)")
                    break
                }
                t += 1
            }
            
            NDebug.Open(
                title: "Interstitial",
                viewController: GetUIViewController(),
                onShow: {
                    self.delegate!.didDisplay(ad)
                    (self.delegate! as! MAAdRevenueDelegate).didPayRevenue(for: ad)
                },
                onClick: { self.delegate!.didClick(ad) },
                onClose: { self.delegate!.didHide(ad) },
                onReward: nil
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
        
        public override var delegate: (any MAAdDelegate)? {
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
        if track._interstitial._ad != nil {
            track._interstitial._ad = nil
  
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
        ad.simFormat = MAAdFormat.interstitial
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
        
        track._interstitial.SimLoad(ad: ad)
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
        track._interstitial.SimFailLoad(error: error)
    }
    
    func SetStatus(t: Int, status: String) {
        _statuses[t].text = status
    }
}
