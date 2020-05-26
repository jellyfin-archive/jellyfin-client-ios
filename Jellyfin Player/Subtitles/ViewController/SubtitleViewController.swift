/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  SubtitleViewController.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 09/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit
import AVFoundation

class SubtitleViewController: UIViewController {

    weak var playerController: PlayerViewControllable?
    var item: PlayableIteming?
    var subtitleStream: MediaStream? {
        didSet {
            updateContent()
        }
    }

    private(set) var subtitles: Subtitles = [] {
        didSet {
            presentSubtitles()
        }
    }

    private var subtitleIndex: Int = 0
    lazy var subtitleLabel: UILabel = self.createSubtitleLabel()

    private var timer: Timer?

    init(playerController: PlayerViewControllable) {
        self.playerController = playerController
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    func presentSubtitles() {
        timer?.invalidate()

        guard subtitleIndex < subtitles.count else {
            subtitleIndex = 0
            return
        }

        guard var currentTime = playerController?.currentTime.seconds else { return }

        while !(subtitles[subtitleIndex].startTime < currentTime && currentTime < subtitles[subtitleIndex].endTime) {
            if subtitles[subtitleIndex].startTime < currentTime,
                subtitleIndex < subtitles.count {
                subtitleIndex += 1
            } else if subtitleIndex > 0 {
                subtitleIndex -= 1
            }
            currentTime = playerController?.currentTime.seconds ?? 0
            guard playerController != nil else { return }
        }

        self.subtitleLabel.attributedText = subtitles[subtitleIndex].subtitle

        if subtitleIndex + 1 < subtitles.count {
            let timeInterval = subtitles[subtitleIndex + 1].startTime - currentTime
            timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: { [weak self] (_) in
                self?.presentSubtitles()
            })
        }
    }

    private func updateContent() {
        subtitleIndex = 0
        guard let subtitleStream = subtitleStream,
            let item = item else {
                subtitles = []
                return
        }
        ServerManager.currentServer?.fetchSubtitle(subtitleStream, for: item) { [weak self] (response) in
            DispatchQueue.main.async {
                switch response {
                case .success(let subtitles):   self?.subtitles = subtitles
                case .failed(let error):        self?.present(error)
                }
            }
        }
    }

    private func present(_ error: Error) {
        print("Error: ", error)
        self.subtitleLabel.text = "There was an error when loading subtitles"
        self.subtitleLabel.textColor = .red
    }

    private func setUpViewController() {
        view.addSubview(subtitleLabel)
        subtitleLabel.fillSuperView()
    }

    private func createSubtitleLabel() -> UILabel {
        let view = UILabel()
        view.textAlignment = .center
        view.textColor = .yellow
        view.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        view.numberOfLines = 0
        return view
    }
}
