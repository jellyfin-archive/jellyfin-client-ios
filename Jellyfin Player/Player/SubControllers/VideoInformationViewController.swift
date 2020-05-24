/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  VideoInformationViewController.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 06/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class VideoInformationViewController: UIViewController {

    var playerInfo: PlayableIteming? {
        didSet {
            updateContent()
        }
    }

    lazy var contentView: UIStackView = self.createContentView()
    lazy var titleLabel: UILabel = self.createTitleLabel()
    lazy var descriptionTextView: UITextView = self.createDescriptionTextView()

    init() {
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViewController()
    }

    func updateContent() {
        guard let playerInfo = playerInfo else { return }
        titleLabel.text = playerInfo.name
        descriptionTextView.text = playerInfo.overview
    }

    // MARK: - View Setup / Init / Config

    private func setUpViewController() {
        view.backgroundColor = .clear
        view.addSubview(contentView)
        contentView.fillSuperView()
        view.isUserInteractionEnabled = false
    }

    private func createContentView() -> UIStackView {
        let arrangedViews = [titleLabel, descriptionTextView]
        let view = UIStackView(arrangedSubviews: arrangedViews)
        view.axis = .vertical
        view.spacing = 10
        return view
    }

    private func createTitleLabel() -> UILabel {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 40, weight: .medium)
        view.textColor = .white
        view.layer.shadowColor = UIColor.black.cgColor
        view.numberOfLines = 0
        return view
    }

    private func createDescriptionTextView() -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isScrollEnabled = false
        view.font = UIFont.systemFont(ofSize: 16)
        view.backgroundColor = .clear
        view.textColor = .white
        return view
    }
}
