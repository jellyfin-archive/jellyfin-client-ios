/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  VideoPlayerControls.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 05/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoPlayerControllsDelegate: class {
    func controllerDidTogglePlay(in controller: VideoPlayerControls)
    func controllerDidScrub(to time: CMTime, in controls: VideoPlayerControls)
}

class VideoPlayerControls: UIViewController {

    lazy var verticalStackView: UIStackView = self.setUpVerticalStackView()

    lazy var progressSliderView: UISlider = self.setUpProgressSliderView()

    lazy var horizontalStackView: UIStackView = self.setUpHorizontalStackView()

    lazy var currentTimeLabel: UILabel = self.setUpTimeLabel()
    lazy var totalTimeLabel: UILabel = self.setUpTimeLabel()

    lazy var scrubBackButton: UIButton = self.setUpScrubBackButton()
    lazy var pauseButton: UIButton = self.setUpPauseButton()
    lazy var playButton: UIButton = self.setUpPlayButton()
    lazy var scrubForwardButton: UIButton = self.setUpScrubForwardButton()

    weak var player: PlayerViewControllable? { didSet { startTimeObserver() } }
    var timer: Timer = Timer()
    weak var delegate: VideoPlayerControllsDelegate?

    init() {
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViewController()
    }

    deinit {
        timer.invalidate()
    }

    private func setUpViewController() {
        view.addSubview(verticalStackView)
        verticalStackView.fillSuperView()
        playButton.isHidden = true
    }

    func updateTimeLabels() {
        guard let currentTime = player?.currentTime,
            !currentTime.seconds.isNaN,
            !currentTime.seconds.isInfinite,
            let duration = player?.duration,
            !duration.seconds.isNaN,
            !duration.seconds.isInfinite,
            let loaded = player?.loadedRange,
            !loaded.isNaN,
            !loaded.isInfinite else { return }

        currentTimeLabel.text = timeString(for: currentTime.seconds)
        totalTimeLabel.text = timeString(for: duration.seconds)

        progressSliderView.value = Float(currentTime.seconds/duration.seconds)
    }

    func startTimeObserver() {
        timer.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self] (_) in
            self?.updateTimeLabels()
        })
    }

    // MARK: - Behavior

    @objc
    private func togglePlayer() {

        guard let player = player else { return }
        startTimeObserver()
        if player.isPlaying == true {
            player.pauseVideo()
        } else {
            player.playVideo()
        }
        playButton.isHidden = player.isPlaying
        pauseButton.isHidden = !player.isPlaying

        delegate?.controllerDidTogglePlay(in: self)
    }

    @objc
    private func scrubBack() {
        guard let currentTime = player?.currentTime else { return }
        let time = CMTime(seconds: currentTime.seconds - 15, preferredTimescale: currentTime.timescale)
        player?.seek(to: time)
        delegate?.controllerDidScrub(to: time, in: self)
    }

    @objc
    private func scrubForward() {
        guard let currentTime = player?.currentTime else { return }
        let time = CMTime(seconds: currentTime.seconds + 15, preferredTimescale: currentTime.timescale)
        player?.seek(to: time)
        delegate?.controllerDidScrub(to: time, in: self)
    }

    @objc
    private func progressSliderDidChangeValue() {
        guard let duration = player?.duration else { return }
        let newTime = CMTime(seconds: duration.seconds * Double(progressSliderView.value), preferredTimescale: duration.timescale)
        delegate?.controllerDidScrub(to: newTime, in: self)
    }

    private func timeString(for duration: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]

        return formatter.string(from: duration) ?? ""
    }

    // MARK: - View setup

    private func setUpVerticalStackView() -> UIStackView {
        let arrangedViews = [progressSliderView, horizontalStackView]
        let view = UIStackView(arrangedSubviews: arrangedViews)
        view.axis = .vertical
        view.spacing = 5
        view.layoutMargins = UIEdgeInsets(top: 5, left: 20, bottom: 5, right: 20)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }

    private func setUpProgressSliderView() -> UISlider {
        let view = UISlider()
        view.minimumValue = 0
        view.maximumValue = 1
        view.minimumTrackTintColor = .green
        view.heightAnchor.constraint(equalToConstant: 40).isActive = true
        view.addTarget(self, action: #selector(progressSliderDidChangeValue), for: .valueChanged)
        return view
    }

    private func setUpHorizontalStackView() -> UIStackView {
        let strechViewOne = self.streatchableView()
        let strechViewTwo = self.streatchableView()

        let arrangedViews = [currentTimeLabel, strechViewOne, scrubBackButton, pauseButton, playButton, scrubForwardButton, strechViewTwo, totalTimeLabel]
        let view = UIStackView(arrangedSubviews: arrangedViews)
        view.spacing = 30

        strechViewOne.widthAnchor.constraint(equalTo: strechViewTwo.widthAnchor, multiplier: 1).isActive = true
        currentTimeLabel.widthAnchor.constraint(equalTo: totalTimeLabel.widthAnchor, multiplier: 1).isActive = true
        return view
    }

    private func setUpTimeLabel() -> UILabel {
        let view = UILabel()
        view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        view.textColor = UIColor(white: 1, alpha: 0.8)
        view.font = UIFont.systemFont(ofSize: 14)
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        return view
    }

    private func setUpScrubBackButton() -> UIButton {
        let view = self.buttonWithImageName("playback-rewind")
        view.addTarget(self, action: #selector(scrubBack), for: .touchUpInside)
        return view
    }

    private func setUpPauseButton() -> UIButton {
        let view = self.buttonWithImageName("pause")
        view.addTarget(self, action: #selector(togglePlayer), for: .touchUpInside)
        return view
    }

    private func setUpPlayButton() -> UIButton {
        let view = self.buttonWithImageName("play")
        view.addTarget(self, action: #selector(togglePlayer), for: .touchUpInside)
        return view
    }

    private func setUpScrubForwardButton() -> UIButton {
        let view = self.buttonWithImageName("playback-fast-forward")
        view.addTarget(self, action: #selector(scrubForward), for: .touchUpInside)
        return view
    }

    private func buttonWithImageName(_ imageName: String) -> UIButton {
        let view = UIButton()
        if let image = UIImage(named: imageName) {
            let tintedImage = image.withRenderingMode(.alwaysTemplate)
            view.setImage(tintedImage, for: .normal)
            view.tintColor = .white
        }
        return view
    }

    private func streatchableView() -> UIView {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.backgroundColor = .clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        return view
    }
}
