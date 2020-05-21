/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  UserView.swift
//  Emby Player
//
//  Created by Mats Mollestad on 22/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class ImageSubtitleView: UIView {

    lazy var imageView: UIImageView = UIImageView()
    lazy var titleLabel: UILabel = UILabel()

    lazy var squareImageConstraint = self.imageView.heightAnchor.constraint(equalTo: self.imageView.widthAnchor, multiplier: 1)

    var imageCornerRadius: CGFloat {
        get { return imageView.layer.cornerRadius }
        set { imageView.layer.cornerRadius = newValue }
    }

    init() {
        super.init(frame: .zero)
        setUpView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }

    private func setUpView() {
        backgroundColor = .black
        addSubview(imageView)
        addSubview(titleLabel)

        showImageView()

        imageView.anchorTo(top: topAnchor,
                           leading: leadingAnchor,
                           trailing: trailingAnchor)
        titleLabel.anchorWithConstantTo(top: imageView.bottomAnchor, topConstant: 10,
                                        leading: leadingAnchor,
                                        trailing: trailingAnchor,
                                        bottom: bottomAnchor)
    }

    func hideImageView() {
        squareImageConstraint.isActive = false
        imageView.isHidden = true
    }

    func showImageView() {
        squareImageConstraint.isActive = true
        imageView.isHidden = false
    }
}

class UserCollectionViewCell: UICollectionViewCell {

    private let infoView = ImageSubtitleView()

    var imageView: UIImageView { return infoView.imageView }
    var titleLabel: UILabel { return infoView.titleLabel }

    var imageCornerRadius: CGFloat {
        get { return infoView.imageCornerRadius }
        set { infoView.imageCornerRadius = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }

    private func setUpView() {
        addSubview(infoView)
        infoView.fillSuperView()

        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
    }
}
