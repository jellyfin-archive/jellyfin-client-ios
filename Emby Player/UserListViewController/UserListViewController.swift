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
    
    func fetchContent(completion: @escaping (FetcherResponse<Void>) -> Void) {
        store.refreshUsers(completion: completion)
    }
    
    
    private func updateForTraitCollection() {
        
        let usableCollectionWidth = view.frame.width - LayoutConstants.collectionInsets.left - LayoutConstants.collectionInsets.right + LayoutConstants.collectionSpacing
        if traitCollection.horizontalSizeClass == .compact {
            let width = (view.frame.width - LayoutConstants.collectionSpacing * 3)/2
            let height = width + LayoutConstants.minCellHeightPadding
            collectionViewFlowLayout.itemSize = CGSize(width: width, height: height)
        } else {
            let numberOfItems = floor(usableCollectionWidth/(LayoutConstants.minCompactCellWidth + LayoutConstants.collectionSpacing))
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


extension UserListViewContentController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.numberOfUsers
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = store.userAt(index: indexPath.row)
        let cell = tableView.cellForItem(at: indexPath, ofType: UITableViewCell.self)
        cell.textLabel?.text = user.name
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = store.userAt(index: indexPath.row)
        delegate?.userWasSelected(user, from: self)
    }
}

extension UserListViewContentController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return store.numberOfUsers
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = store.userAt(index: indexPath.row)
        let cell = collectionView.cellForItem(at: indexPath, ofType: UserCollectionViewCell.self)
        
        cell.imageView.image = UIImage(named: "User Image")
        if let userImageUrl = ServerManager.currentServer?.baseUrl.appendingPathComponent("emby/Users/\(user.id)/Images/Primary") {
            _ = cell.imageView.fetch(userImageUrl)
        }
        cell.titleLabel.text = user.name
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = store.userAt(index: indexPath.row)
        delegate?.userWasSelected(user, from: self)
    }
}
