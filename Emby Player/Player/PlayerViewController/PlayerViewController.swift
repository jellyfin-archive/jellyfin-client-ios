//
//  PlayerViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 29/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit
import AVKit

struct Video {
    let url: URL
    var isHLS: Bool {
        return url.pathExtension == "m3u8"
    }
}

protocol PlayerViewControllable: class {
    
    var video: Video? { get set }
    var currentTime: CMTime { get }
    var duration: CMTime { get }
    var loadedRange: Double { get }
    var isPlaying: Bool { get }
    
    func supports(format: String) -> Bool
    func playVideo()
    func pauseVideo()
    func seek(to time: CMTime)
}


protocol PlayerViewControllerDelegate: class {
    func playerWillDisappear(_ player: PlayerViewController)
}

class PlayerViewController: UIViewController, PlayerViewControllable {
    
    
    var video: Video? { didSet { updatePlayer() } }
    var subtitleStream: MediaStream? {
        get { return subtitleViewController.subtitleStream }
        set { subtitleViewController.subtitleStream = newValue }
    }
    var playableItem: PlayableIteming? {
        didSet {
            if let urlPath = playableItem?.diskUrlPath {
                do {
                    let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let url = directory.appendingPathComponent(urlPath)
                    video = Video(url: url)
                } catch {
                    print("Error Loadin directory:", error)
                }
            } else if let server = ServerManager.currentServer {
                video = playableItem?.playableVideo(in: self, from: server)
            }
            playerInfoViewController.playerInfo = playableItem
            subtitleViewController.item = playableItem
        }
    }
    
    weak var delegate: PlayerViewControllerDelegate?
    
    var currentTime: CMTime     { return player?.currentTime() ?? CMTime(seconds: 0, preferredTimescale: 0) }
    var duration: CMTime        { return player?.currentItem?.duration ?? CMTime(seconds: 0, preferredTimescale: 0) }
    var player: AVPlayer?       { return playerLayer.player }
    var isPlaying: Bool         { return player?.rate != 0 && player?.error == nil }
    var loadedRange: Double     {
        guard let range = (player?.currentItem?.loadedTimeRanges.first as? CMTimeRange) else { return 0 }
        return range.start.seconds + range.duration.seconds
    }
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
    
    
    private lazy var genericControlsView: UIStackView = self.setUpGenericControllsContentView()
    private lazy var settingsButton: UIButton = self.setUpSettingsButton()
    private lazy var dismissButton: UIButton = self.setUpDismissButton()
    private lazy var playerControls: VideoPlayerControls = self.setUpControlls()
    private lazy var playerInfoViewController: VideoInformationViewController = VideoInformationViewController()
    private lazy var overlayView: UIView = self.setUpOverlayView()
    private lazy var subtitleViewController: SubtitleViewController = SubtitleViewController(playerController: self)
    
    private var errorViewController: ErrorViewController?
    private var playerLayer = AVPlayerLayer()
    
    private var hideTimer: Timer?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViewController()
    }
    
    private func setUpViewController() {
        
        view.layer.addSublayer(playerLayer)
        
        add(subtitleViewController)
        subtitleViewController.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        subtitleViewController.view.anchorWithConstantTo(leading: view.layoutMarginsGuide.leadingAnchor, leadingConstant: 10,
                                                         trailing: view.layoutMarginsGuide.trailingAnchor, trailingConstant: -10,
                                                         bottom: view.bottomAnchor, bottomConstant: -20)
        
        view.addSubview(overlayView)
        overlayView.fillSuperView()
        
        view.backgroundColor = .black
        view.addSubview(genericControlsView)
        genericControlsView.anchorWithConstantTo(top: view.layoutMarginsGuide.topAnchor, topConstant: 10,
                                                 leading: view.layoutMarginsGuide.leadingAnchor, leadingConstant: 10)
        
        add(playerInfoViewController)
        playerInfoViewController.view.anchorWithConstantTo(top: view.layoutMarginsGuide.topAnchor,
                                                           leading: view.centerXAnchor, leadingConstant: -50,
                                                           trailing: view.layoutMarginsGuide.trailingAnchor)
        
        add(playerControls)
        playerControls.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        playerControls.view.anchorWithConstantTo(leading: view.layoutMarginsGuide.leadingAnchor, leadingConstant: 10,
                                                 trailing: view.layoutMarginsGuide.trailingAnchor, trailingConstant: -10,
                                                 bottom: view.bottomAnchor, bottomConstant: -20)
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidUpdate), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    
    override func viewDidLoad() {
        if #available(iOS 11, *) {
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playerLayer.frame = view.bounds
    }
    
    
    
    private func updatePlayer() {
        self.player?.removeObserver(self, forKeyPath: "rate")
        self.player?.removeObserver(self, forKeyPath: "error")
        guard let video = video else { return }
        print("Playing video at:", video.url)
        let player = AVPlayer(url: video.url)
        playerLayer.removeFromSuperlayer()
        playerLayer = AVPlayerLayer(player: player)
        view.layer.insertSublayer(playerLayer, at: 0)
        playerLayer.frame = view.bounds
        player.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
        player.addObserver(self, forKeyPath: "error", options: .new, context: nil)
    }
    
    func playVideo() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: AVAudioSession.CategoryOptions.allowAirPlay)
        } catch let error {
            print("Unable to set mode: \(error)")
        }
        
        player?.play()
        updateHideTimer()
    }
    
    func pauseVideo() {
        player?.pause()
        subtitleViewController.presentSubtitles()
    }
    
    func seek(to time: CMTime) {
        pauseVideo()
        player?.seek(to: time, completionHandler: { [weak self] (_) in
            self?.playVideo()
            self?.subtitleViewController.presentSubtitles()
        })
    }
    
    func supports(format: String) -> Bool {
        return AVURLAsset.audiovisualMIMETypes().contains("video/" + format)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "rate": playerControls.updateTimeLabels()
        case "error": handleError()
        default: break
        }
    }
    
    
    
    func handleError() {
        print("Error: ", player?.error?.localizedDescription ?? "nil")
        errorViewController?.remove()
        let error = player?.error ?? DownloadManager.Errors.unknownError
        errorViewController = ErrorViewController(error: error) { [weak self] in
            self?.errorViewController?.remove()
            self?.updateHideTimer()
        }
        errorViewController?.view.backgroundColor = .black
        add(errorViewController!)
        errorViewController?.view.fillSuperView()
        view.bringSubviewToFront(genericControlsView)
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    @objc
    func orientationDidUpdate() {
        playerLayer.frame = view.bounds
    }
    
    
    @objc
    func presentControlls() {
        updateHideTimer()
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.playerControls.view.alpha = 1
            self?.playerControls.view.isUserInteractionEnabled = true
            self?.genericControlsView.alpha = 1
            self?.genericControlsView.isUserInteractionEnabled = true
            self?.playerInfoViewController.view.alpha = 1
            self?.overlayView.backgroundColor = UIColor(white: 0, alpha: 0.4)
        }
    }
    
    
    @objc
    private func dismissViewController() {
        NotificationCenter.default.removeObserver(self)
        player?.removeObserver(self, forKeyPath: "rate")
        player?.removeObserver(self, forKeyPath: "error")
        delegate?.playerWillDisappear(self)
        playerLayer.player = nil
        subtitleViewController.playerController = nil
        playerControls.player = nil
        self.dismiss(animated: true, completion: nil)
        DispatchQueue.global().async {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            } catch let error {
                print("Unable to set mode: \(error)")
            }
        }
    }
    
    
    @objc
    private func presentSettings() {
        let subtitleActions = UIAlertController(title: "Subtitle", message: nil, preferredStyle: .actionSheet)
        guard let subtitles = playableItem?.mediaStreams.filter({ $0.type == "Subtitle" }) else { return }
        let actions = subtitles.map { subtitleOption in
            UIAlertAction(title: subtitleOption.displayTitle, style: .default, handler: { [weak self] (_) in
                self?.subtitleStream = subtitleOption
            })
        }
        let noAction = UIAlertAction(title: "No Subtitles", style: .default) { [weak self] (_) in
            self?.subtitleStream = nil
        }
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        (actions + [noAction, cancel]).forEach { (action) in
            subtitleActions.addAction(action)
        }
        subtitleActions.popoverPresentationController?.sourceView = settingsButton
        present(subtitleActions, animated: true, completion: nil)
    }
    
    
    func hideControlls() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.playerControls.view.alpha = 0
            self?.playerControls.view.isUserInteractionEnabled = false
            self?.genericControlsView.alpha = 0
            self?.genericControlsView.isUserInteractionEnabled = false
            self?.playerInfoViewController.view.alpha = 0
            self?.overlayView.backgroundColor = .clear
        }
    }
    
    
    private func updateHideTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false, block: { [weak self] (_) in
            if self?.hideTimer != nil {
                self?.hideControlls()
                self?.hideTimer?.invalidate()
                self?.hideTimer = nil
            }
        })
    }
    
    
    // MAKR: - View configs / setup code
    
    private func setUpGenericControllsContentView() -> UIStackView {
        let arrangedViews = [dismissButton, settingsButton]
        let view = UIStackView(arrangedSubviews: arrangedViews)
        view.spacing = 5
        return view
    }
    
    private func setUpSettingsButton() -> UIButton {
        let button = buttonWithImageName("close-quote")
        button.addTarget(self, action: #selector(presentSettings), for: .touchUpInside)
        return button
    }
    
    private func setUpOverlayView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(presentControlls))
        view.addGestureRecognizer(tapGesture)
        return view
    }
    
    private func setUpDismissButton() -> UIButton {
        let button = buttonWithImageName("cross")
        button.addTarget(self, action: #selector(dismissViewController), for: .touchUpInside)
        return button
    }
    
    private func setUpControlls() -> VideoPlayerControls {
        let controller = VideoPlayerControls()
        controller.player = self
        controller.delegate = self
        return controller
    }
    
    private func buttonWithImageName(_ imageName: String) -> UIButton {
        let view = UIButton()
        if let image = UIImage(named: imageName) {
            let tintedImage = image.withRenderingMode(.alwaysTemplate)
            view.setImage(tintedImage, for: .normal)
            view.tintColor = .white
        }
        view.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return view
    }
}


extension PlayerViewController: VideoPlayerControllsDelegate {
    
    func controllerDidTogglePlay(in controller: VideoPlayerControls) {
        updateHideTimer()
    }
    
    func controllerDidScrub(to time: CMTime, in controls: VideoPlayerControls) {
        seek(to: time)
        updateHideTimer()
    }
}
