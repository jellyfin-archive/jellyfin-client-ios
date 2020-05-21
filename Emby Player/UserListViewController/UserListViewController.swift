/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  UserListViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 25/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

protocol UserListViewControllerDelegate: class {
    func userWasSelected(_ user: User, from userListViewController: UserListViewContentController)
    func loginManually(from userListViewController: UserListViewContentController)
    func disconnectFromServer()
}

class UserListViewContentController: UIViewController, ContentViewControlling {

    private struct LayoutConstants {
        static let collectionInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        static let collectionSpacing: CGFloat = 20
        static let minCompactCellWidth: CGFloat = 150
        static let minCellHeightPadding: CGFloat = 30
    }

    var contentViewController: UIViewController { return self }

    lazy var collectionView: UICollectionView = self.createCollectionView()
    private lazy var collectionViewFlowLayout: UICollectionViewFlowLayout = self.createCollectionFlowLayout()
    lazy var disconnectBarButton = UIBarButtonItem(title: "Disconnect", style: .done, target: self, action: #selector(disconnectFromServer))
    lazy var manuallyLoginButton = UIBarButtonItem(title: "Login Manually", style: .done, target: self, action: #selector(loginManually))

    let store: UserListStore

    weak var delegate: UserListViewControllerDelegate?

    init(fetcher: UserListStoreFetchable) {
        store = UserListStore(fetcher: fetcher)
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder: aDecoder: NSCoder) not implemented")
    }

    @objc func disconnectFromServer() {
        delegate?.disconnectFromServer()
    }

    @objc func loginManually() {
        delegate?.loginManually(from: self)
    }

    func fetchContent(completion: @escaping (FetcherResponse<Void>) -> Void) {
        store.refreshUsers(completion: completion)
    }

    private func updateForTraitCollection() {

        guard store.hasUsers else {
            let width = view.bounds.width - LayoutConstants.collectionSpacing * 2
            let height = width + LayoutConstants.minCellHeightPadding * 3
            collectionViewFlowLayout.itemSize = CGSize(width: width, height: height)
            return
        }

        let usableCollectionWidth =
            LayoutConstants.collectionSpacing + view.frame.width
                - LayoutConstants.collectionInsets.left - LayoutConstants.collectionInsets.right
        if traitCollection.horizontalSizeClass == .compact {
            let width = (view.frame.width - LayoutConstants.collectionSpacing * 3)/2
            let height = width + LayoutConstants.minCellHeightPadding
            collectionViewFlowLayout.itemSize = CGSize(width: width, height: height)
        } else {
            let numberOfItems =
                floor(usableCollectionWidth
                    / (LayoutConstants.minCompactCellWidth + LayoutConstants.collectionSpacing))
            let width = usableCollectionWidth/numberOfItems
            let height = width + LayoutConstants.minCellHeightPadding
            collectionViewFlowLayout.itemSize = CGSize(width: width, height: height)
        }
        collectionView.reloadData()
    }

    private func setUpViewController() {
        title = "Users"
        view.backgroundColor = .clear
        view.addSubview(collectionView)
        collectionView.fillSuperView()
        navigationItem.leftBarButtonItem = disconnectBarButton
        navigationItem.rightBarButtonItem = manuallyLoginButton
        updateForTraitCollection()
    }

    private func createCollectionFlowLayout() -> UICollectionViewFlowLayout {
        let viewLayout = UICollectionViewFlowLayout()
        viewLayout.minimumLineSpacing = LayoutConstants.collectionSpacing
        return viewLayout
    }

    private func createCollectionView() -> UICollectionView {

        let view = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewFlowLayout)
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = .clear
        view.register(UserCollectionViewCell.self)
        view.contentInset = LayoutConstants.collectionInsets
        return view
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            updateForTraitCollection()
        }
    }
}
//
//extension UserListViewContentController: UITableViewDataSource, UITableViewDelegate {
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if store.hasUsers {
//            return store.numberOfUsers
//        } else {
//            return 1
//        }
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.cellForItem(at: indexPath, ofType: UITableViewCell.self)
//        if store.hasUsers {
//            configUserContent(for: cell, at: indexPath.row)
//        } else {
//            configNoUsersContent(for: cell)
//        }
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let user = store.userAt(index: indexPath.row)
//        delegate?.userWasSelected(user, from: self)
//    }
//}

extension UserListViewContentController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if store.hasUsers {
            return store.numberOfUsers
        } else {
            return 1
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.cellForItem(at: indexPath, ofType: UserCollectionViewCell.self)
        if store.hasUsers {
            configUserContent(for: cell, at: indexPath.row)
        } else {
            configNoUsersContent(for: cell)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if store.hasUsers {
            let user = store.userAt(index: indexPath.row)
            delegate?.userWasSelected(user, from: self)
        } else {
            delegate?.loginManually(from: self)
        }
    }

    private func configNoUsersContent(for cell: UserCollectionViewCell) {
        cell.titleLabel.text = "There are no visable users. Tap here to log in manually."
        cell.imageView.image = nil
    }

    private func configUserContent(for cell: UserCollectionViewCell, at index: Int) {
        let user = store.userAt(index: index)

        cell.imageView.image = UIImage(named: "User Image")
        if let userImageUrl = ServerManager.currentServer?.profileImageUrl(for: user) {
            _ = cell.imageView.fetch(userImageUrl)
        }
        cell.titleLabel.text = user.name
    }
}
