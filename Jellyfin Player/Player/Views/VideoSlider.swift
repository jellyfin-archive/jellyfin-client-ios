/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  VideoSlider.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 05/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class VideoSlider: UISlider {

    var trackHeight: CGFloat = 8

    var loadingTrackColor: UIColor = .red {
        didSet {
            loadingTrack.backgroundColor = loadingTrackColor
        }
    }
    var loadingTrackValue: Float = 0 {
        didSet {
            updateLoadingTrack()
        }
    }
    override var bounds: CGRect {
        didSet {
            updateLoadingTrack()
        }
    }
    private var loadingTrack: UIView = UIView()

    init() {
        super.init(frame: .zero)
        setUpViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViews()
    }

    private func setUpViews() {
        addSubview(loadingTrack)
        loadingTrack.backgroundColor = loadingTrackColor
    }

    private func updateLoadingTrack() {
        let rect = trackRect(forBounds: bounds)
        let startValue = rect.width * CGFloat(value)
        let loadingWidth = max(rect.width * CGFloat(loadingTrackValue) - startValue, 0)
        loadingTrack.frame = CGRect(x: rect.origin.x + startValue, y: rect.origin.y, width: loadingWidth, height: rect.height)
        loadingTrack.layer.cornerRadius = trackHeight / 2
    }

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let origin = CGPoint(x: bounds.origin.x, y: frame.size.height / 2 - trackHeight)
        return CGRect(origin: origin, size: CGSize(width: bounds.width, height: trackHeight))
    }
}
