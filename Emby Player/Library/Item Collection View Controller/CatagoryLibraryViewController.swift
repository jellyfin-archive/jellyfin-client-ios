/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  CatagoryLibraryViewController.swift
//  Emby Player
//
//  Created by Mats Mollestad on 30/08/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

protocol CatagoryLibraryViewControllerDelegate: class {
    func itemWasSelected(_ item: BaseItem)
}

class CatagoryLibraryViewController<Fetcher: LibraryStoreFetchable>: UIViewController, ContentViewControlling, UICollectionViewDataSource, UICollectionViewDelegate where Fetcher.LibraryItem == BaseItem {

    private(set) var store: LibraryStore<Fetcher>

    var contentViewController: UIViewController {
        collectionView.reloadData()
        return self
    }

    var collectionViewHeader: UIView? {
        didSet {
            collectionViewHeader?.removeFromSuperview()
            view.addSubview(collectionViewHeader!)
            collectionViewHeader?.anchorTo(top: view.layoutMarginsGuide.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor)
        }
    }

    private lazy var layout: UICollectionViewFlowLayout = self.seUpCollectionViewLayout()
    lazy var collectionView: UICollectionView = self.setUpCollectionView()

    weak var delegate: CatagoryLibraryViewControllerDelegate?

    init(fetcher: Fetcher) {
        self.store = LibraryStore(fetcher: fetcher)
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    init(store: LibraryStore<Fetcher>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
        setUpViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {

        if let collectionViewHeader = collectionViewHeader {
            collectionViewHeader.removeFromSuperview()
            view.addSubview(collectionViewHeader)
            collectionViewHeader.anchorTo(top: view.layoutMarginsGuide.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor)
        }
    }

    func fetchContent(completion: @escaping (FetcherResponse<Void>) -> Void) {
        store.fetchItems(completion: completion)
    }

    func update(_ store: LibraryStore<Fetcher>) {
        self.store = store
    }

    private func setUpViewController() {
        view.backgroundColor = .black
        view.addSubview(collectionView)
        collectionView.fillSuperView()
    }

    private func seUpCollectionViewLayout() -> UICollectionViewFlowLayout {
        let minWidth: CGFloat = 150
        let spacing: CGFloat = 10
        let numberOfCells = floor(self.view.frame.width / minWidth)
        let width = (self.view.frame.width - (numberOfCells - 1) * spacing) / numberOfCells
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = spacing
        layout.itemSize = CGSize(width: width, height: 200)
        return layout
    }

    private func setUpCollectionView() -> UICollectionView {

        let view = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        view.delegate = self
        view.dataSource = self
        view.register(BaseItemCollectionViewCell.self)
        view.backgroundColor = .clear
        view.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        view.alwaysBounceVertical = true
        view.register(UICollectionReusableView.self, forSupplementryViewOfKind: UICollectionView.elementKindSectionHeader)
        return view
    }

    private func handleSelection(of item: BaseItem) {

        let contentController: ContentViewControlling!

        if item.type == "Series" {
            let showFetcher = TvShowLigraryStoreEmbyFetcher(serieId: item.id)
            contentController = TvShowLibraryViewController(fetcher: showFetcher)
        } else if item.isFolder == true {
            let mediaFoler = MediaFolder(item: item)
            let fetcher = LibraryStoreEmbyCatagoryFetcher(catagory: mediaFoler)
            contentController = CatagoryLibraryViewController<LibraryStoreEmbyCatagoryFetcher>(fetcher: fetcher)
        } else {
            if store.fetcher is LibraryStoreOfflineItemFetcher {
                let itemFetcher = SingleItemOfflineFetcher(itemId: item.id)
                contentController = ItemViewController(fetcher: itemFetcher)
            } else {
                let itemFetcher = SingleItemStoreEmbyFetcher(itemId: item.id)
                contentController = ItemViewController(fetcher: itemFetcher)
            }
        }
        let contentStateController = ContentStateViewController(contentController: contentController, fetchMode: .onAppeare, backgroundColor: .black)
        navigationController?.pushViewController(contentStateController, animated: true)
        contentStateController.title = item.seriesName ?? item.name
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return store.numberOfItems
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let item = store.itemAt(index: indexPath.row)

        let cell = collectionView.cellForItem(at: indexPath, ofType: BaseItemCollectionViewCell.self)
        cell.titleLabel.text = item.name
        cell.superController = self
        cell.imageUrl = ServerManager.currentServer?.imageUrl(of: .primary, itemId: item.id)
        cell.playedUserData = item.userData
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = store.itemAt(index: indexPath.row)
        delegate?.itemWasSelected(item)
//        handleSelection(of: item)
    }
}
