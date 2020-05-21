/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  BaseItemCollectionViewCell.swift
//  Emby Player
//
//  Created by Mats Mollestad on 28/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class BaseItemCollectionViewCell: UICollectionViewCell {

    lazy var stackView: UIStackView = self.setUpStackView()
    lazy var titleLabel: UILabel = self.setUpTitleLabel()
    lazy var imageView: UIImageView = self.setUpImageView()
    lazy var imageLoaderController = ImageLoaderViewController()

    lazy var playStatusView = self.setUpUnplayedView()
    lazy var unplayedCountLabel = self.setUpUnplayedConutLabel()
    lazy var playedImageView = self.createPlayedImageView()

    var superController: UIViewController? {
        willSet {
            if superController != nil {
                imageLoaderController.remove()
            }
            if newValue != nil {
                stackView.insertArrangedSubview(imageLoaderController.view, at: 0)
                newValue?.addChild(imageLoaderController)
                imageLoaderController.didMove(toParent: newValue)
            }
        }
    }

    var imageUrl: URL? {
        didSet {
            loadImage()
        }
    }
    var playedUserData: UserData? {
        didSet {
            if let userData = playedUserData {
                update(with: userData)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpCell()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpCell()
    }

    private func setUpCell() {
        backgroundColor = .clear
        addSubview(stackView)
        addSubview(playStatusView)
        stackView.fillSuperView()
        playStatusView.anchorWithConstantTo(top: topAnchor, topConstant: 3, trailing: trailingAnchor, trailingConstant: -8)
    }

    private func setUpStackView() -> UIStackView {
        let view = UIStackView(arrangedSubviews: [titleLabel])
        view.axis = .vertical
        view.spacing = 5
        view.layoutMargins = UIEdgeInsets(top: 0, left: 2, bottom: 2, right: 2)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }

    private func setUpTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }

    private func setUpImageView() -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }

    private func setUpUnplayedView() -> UIView {
        let view = UIView()
        let size: CGFloat = 20
        view.backgroundColor = .green
        view.heightAnchor.constraint(equalToConstant: size).isActive = true
        view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1).isActive = true
        view.layer.cornerRadius = size / 2
        view.isHidden = true

        view.addSubview(unplayedCountLabel)
        view.addSubview(playedImageView)

        unplayedCountLabel.fillSuperView()
        playedImageView.fillSuperView(topConstant: 2, leadingConstant: 2, trailingConstant: -2, bottomConstant: -2)

        return view
    }

    private func setUpUnplayedConutLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        return label
    }

    private func createPlayedImageView() -> UIImageView {
        let view = UIImageView(image: UIImage(named: "tick"))
        view.contentMode = .scaleAspectFit
        return view
    }

    private func loadImage() {
        guard let url = imageUrl else { return }

        imageLoaderController.imageUrl = url
        imageLoaderController.fetchContent()
    }

    private func update(with userData: UserData) {

        unplayedCountLabel.text = ""
        playedImageView.isHidden = userData.unplayedItemCount != nil
        playStatusView.isHidden = !userData.played

        if let unplayedItemCount = userData.unplayedItemCount {
            playStatusView.isHidden = false
            unplayedCountLabel.text = "\(unplayedItemCount)"
        }

    }
}
