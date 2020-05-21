/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  CatagoryTableViewCell.swift
//  Emby Player
//
//  Created by Mats Mollestad on 27/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

class MediaFolderTableViewCell: UITableViewCell {

    private struct ViewConstants {
        static let titleContentViewSpacing: CGFloat = 10
        static let titleContentViewMargins: UIEdgeInsets = UIEdgeInsets(top: 20, left: 16, bottom: 0, right: 0)

        static let contentStackViewSpacing: CGFloat = 20
        static let contentStackViewMargins: UIEdgeInsets = .zero
    }

    var catagoryController: HorizontalCatagoryLatestLibraryViewController?
    var controller: ContentStateViewController?

    var catagory: MediaFolder? {
        didSet {
            updateForCatagory()
        }
    }

    lazy var titleLabel: UILabel = self.setUpTitleLabel()
    lazy var accessoryImageView: UIImageView = self.createAccessoryImageView()
    lazy var titleContentView: UIStackView = self.setUpContentStackView(views: [self.titleLabel, self.accessoryImageView, UIView()],
                                                                        axis: .horizontal,
                                                                        spacing: ViewConstants.titleContentViewSpacing,
                                                                        margins: ViewConstants.titleContentViewMargins)
    lazy var contentStackView: UIStackView = self.setUpContentStackView(views: [self.titleContentView],
                                                                        axis: .vertical,
                                                                        spacing: ViewConstants.contentStackViewSpacing,
                                                                        margins: ViewConstants.contentStackViewMargins)

    var superViewController: UIViewController?
    weak var delegate: HorizontalCatagoryLibraryViewControllerDelegate? {
        didSet {
            catagoryController?.delegate = delegate
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpCell()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpCell()
    }

    private func updateForCatagory() {

        guard let catagory = catagory else { return }
        guard let superViewController = superViewController else { return }

        titleLabel.text = catagory.name

        controller?.willMove(toParent: nil)
        controller?.view.removeFromSuperview()
        controller?.removeFromParent()
        catagoryController = HorizontalCatagoryLatestLibraryViewController(catagory: catagory)
        catagoryController?.delegate = delegate
        controller = ContentStateViewController(contentController: catagoryController!, fetchMode: .onAppeare)

        guard let subView = controller?.view else { return }
        subView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        contentStackView.removeArrangedSubview(subView)
        contentStackView.addArrangedSubview(subView)
        superViewController.addChild(controller!)
        controller?.didMove(toParent: superViewController)
    }

    private func setUpCell() {
        addSubview(contentStackView)
        contentStackView.fillSuperView()
        selectionStyle = .none
    }

    private func setUpTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        return label
    }

    private func createAccessoryImageView() -> UIImageView {
        let image = UIImage(named: "chevron-right")?.withRenderingMode(.alwaysTemplate)
        let view = UIImageView(image: image)
        view.tintColor = self.titleLabel.textColor
        view.alpha = 0.8
        view.contentMode = .scaleAspectFit
        return view
    }

    private func setUpContentStackView(views: [UIView], axis: NSLayoutConstraint.Axis, spacing: CGFloat, margins: UIEdgeInsets) -> UIStackView {
        let view = UIStackView(arrangedSubviews: views)
        view.axis = axis
        view.spacing = spacing
        view.layoutMargins = margins
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }
}
