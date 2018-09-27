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
    
    
    var contentViewController: UIViewController { return self }
    
    lazy var collectionView: UICollectionView = self.createCollectionView()
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
    
    
    private func setUpViewController() {
        title = "Users"
        view.backgroundColor = .clear
        view.addSubview(collectionView)
        collectionView.fillSuperView()
        navigationItem.leftBarButtonItem = disconnectBarButton
    }
    
    private func createCollectionView() -> UICollectionView {
        let width = (self.view.frame.width - 20 * 3)/2
        let height = width + 30
        let viewLayout = UICollectionViewFlowLayout()
        viewLayout.itemSize = CGSize(width: width, height: height)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: viewLayout)
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = .clear
        view.register(UserCollectionViewCell.self)
        view.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        return view
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
            cell.imageView.fetch(userImageUrl)
        }
        cell.titleLabel.text = user.name
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = store.userAt(index: indexPath.row)
        delegate?.userWasSelected(user, from: self)
    }
}
