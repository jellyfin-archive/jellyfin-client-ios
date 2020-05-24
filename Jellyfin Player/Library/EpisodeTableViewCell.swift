/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  BaseItemTableViewCell.swift
//  Jellyfin Player
//
//  Created by Mats Mollestad on 29/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class EpisodeTableViewCell: UITableViewCell {

    var episode: PlayableEpisode? {
        didSet {
            if let episode = episode {
                update(with: episode)
            }
        }
    }

    lazy var horizontalStackView: UIStackView   = self.setUpHorizontalStackView()
    lazy var textStackView: UIStackView         = self.setUpTextStackView()
    lazy var titleLabel: UILabel                = self.setUpTitleLabel()
    lazy var indexLabel: UILabel                = self.setUpIndexLabel()
    lazy var playedLabel: UILabel               = self.setUpPlayedLabel()
    lazy var descriptionTextView: UITextView    = self.setUpDescriptionTextView()
    lazy var previewImageView: UIImageView      = self.setUpImageView()

    private var imageFetchTask: URLSessionTask?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViews()
    }

    private func setUpViews() {
        backgroundColor = .clear
        addSubview(horizontalStackView)
        horizontalStackView.fillSuperViewToSafeArea()
    }

    // MARK: - View setup / init / config

    private func setUpHorizontalStackView() -> UIStackView {
        let views = [previewImageView, textStackView]
        let view = UIStackView(arrangedSubviews: views)
        view.spacing = 5
        view.alignment = .center
        return view
    }

    private func setUpTextStackView() -> UIStackView {
        let views = [titleLabel, indexLabel, playedLabel]
        let view = UIStackView(arrangedSubviews: views)
        view.axis = .vertical
        view.spacing = 5
        view.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 5)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }

    private func setUpTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.numberOfLines = 2
        label.textColor = .white
        return label
    }

    private func setUpIndexLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }

    private func setUpPlayedLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(white: 1, alpha: 0.6)
        return label
    }

    private func setUpDescriptionTextView() -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isScrollEnabled = false
        return view
    }

    private func setUpImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9/16).isActive = true
        return imageView
    }

    func update(with episode: PlayableEpisode) {
        titleLabel.text = episode.name
        indexLabel.text = episode.episodeText
        playedLabel.text = episode.userData.played ? "Watched ✅" : "Unwatched 🙈"
        descriptionTextView.text = episode.overview

        imageFetchTask?.cancel()
        if let url = ServerManager.currentServer?.imageUrl(of: .primary, itemId: episode.id) {
            imageFetchTask = previewImageView.fetch(url)
        }
    }
}
