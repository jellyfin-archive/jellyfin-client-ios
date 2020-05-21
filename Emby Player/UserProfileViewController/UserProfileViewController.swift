/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  UserProfileViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 31/05/2019.
//  Copyright © 2019 Mats Mollestad. All rights reserved.
//

import UIKit

protocol UserProfileViewControllerDelegate: class {
    func userDidLogout(_ user: User)
}

class UserProfileViewController: UIViewController {

    var store: UserProfileStore = UserManager.shared
    weak var delegate: UserProfileViewControllerDelegate?

    var imageFetchTask: URLSessionTask?

    lazy var scrollView: UIScrollView           = self.setupScrollView()
    lazy var contentView: UIStackView           = self.setupContentView()
    lazy var userInfoView: ImageSubtitleView    = self.setupUserInfoView()
    lazy var logoutButton: UIButton             = self.setupLogoutButton()

    init() {
        super.init(nibName: nil, bundle: nil)
        setupViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViewController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContent()
    }

    @objc
    func logoutWasTapped() {
        guard let user = store.current else { return }
        delegate?.userDidLogout(user)
    }

    private func setupViewController() {
        title = "Profile"
        tabBarItem.image = #imageLiteral(resourceName: "User")
        view.addSubview(scrollView)
        scrollView.fillSuperView()
    }

    private func updateContent() {

        imageFetchTask?.cancel()
        imageFetchTask = nil
        guard let user = store.current else { return }

        if let profileUrl = store.profileImageURL {
            userInfoView.showImageView()
            imageFetchTask = userInfoView.imageView.fetch(profileUrl) { [weak self] (_) in
                DispatchQueue.main.async {
                    self?.userInfoView.hideImageView()
                }
            }
        } else {
            userInfoView.hideImageView()
        }
        userInfoView.titleLabel.text = user.name
    }

    private func setupScrollView() -> UIScrollView {
        let view = UIScrollView()
        view.addSubview(contentView)
        view.alwaysBounceVertical = true
        contentView.fillSuperView()
        contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        return view
    }

    private func setupContentView() -> UIStackView {
        let view = UIStackView(arrangedSubviews: [userInfoView, logoutButton])
        view.spacing = 25
        view.axis = .vertical
        view.layoutMargins = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }

    private func setupUserInfoView() -> ImageSubtitleView {
        let view = ImageSubtitleView()
        view.titleLabel.textColor = .white
        return view
    }

    private func setupLogoutButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .red
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(logoutWasTapped), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }
}
